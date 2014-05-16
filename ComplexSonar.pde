import SimpleOculusRift.*;
import SimpleOpenNI.*;
import ddf.minim.analysis.*;
import ddf.minim.*;

static final int IMPULSE_COOLDOWN_TIME = 500;
static final int ROOM_RESOLUTION = 8; // lower = better
static final boolean USE_COLOR_IMAGE = false; // does not work in completly dark environments
static final boolean RUN_FULLSCREEN = true;
static final float IMPULSE_THRESHOLD = 20.0;
static final float MAX_Z_DEPTH = 7.0; // meters
static final float BLUR_SHIFT = 0.08;
static final float STANDARD_SHIFT = 0.06;
static final float MAX_FREQUENCE_INDEX = 4;

Minim minim;
AudioInput input;
FFT fft;
SimpleOpenNI context;
SimpleOculusRift oculus;

float lastImpulseTime = .0;
boolean impulseCooldown = true;

PImage rgbImage;
int[] depthMap;
PVector[] realWorldDepthMap;

PMatrix3D headOrientation;

void setup() {
  size(1280, 800, OPENGL);

  oculus = new SimpleOculusRift(this, SimpleOculusRift.RenderQuality_Middle); 
  oculus.setBknColor(0, 0, 0); 

  strokeWeight(.3);

  context = new SimpleOpenNI(this, SimpleOpenNI.RUN_MODE_MULTI_THREADED);

  if (context.isInit() == false) {
    println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
    exit();
    return;
  }

  context.setMirror(true); 
  context.enableDepth();
  context.enableRGB();
  context.setDepthColorSyncEnabled(true);

  minim = new Minim(this);
  input = minim.getLineIn(Minim.STEREO, 512);
  fft = new FFT(input.bufferSize(), input.sampleRate());
}

void draw() {
  headOrientation = oculus.headOrientationMatrix(); 
  headOrientation.rotateY(radians(180));
  headOrientation.translate(0, 0, -0.5);

  context.update();
  
  float loudestFrequence = getLoudestFrequence(IMPULSE_THRESHOLD);
  // maxFrequenceIndex - getLoudestFrequence(IMPULSE_THRESHOLD);
  // println(loudestFrequence);
  
  if (loudestFrequence >= 0 && impulseCooldown) { 
    addNewImpulse(new PVector(0, 0, 0), 1.0, int(loudestFrequence));
    lastImpulseTime = millis();
    impulseCooldown = false;
  }
  
  if (millis() - lastImpulseTime >= IMPULSE_COOLDOWN_TIME) {
    impulseCooldown = true;
  }

  depthMap = context.depthMap();
  realWorldDepthMap = context.depthMapRealWorld();

  rgbImage = context.rgbImage();
  
  updateImpulses();
  
  oculus.draw();
} 

void onDrawScene(int eye) {
  pushMatrix();
  applyMatrix(headOrientation);

  strokeWeight((float)ROOM_RESOLUTION/2.0);

  int currentMapIndex;
  PVector currentPoint;
  float currentPointIntensity = 0;
  color currentPointColor;

  beginShape(POINTS);

  for (int y=0; y < context.depthHeight(); y += ROOM_RESOLUTION) {
    for (int x=0; x < context.depthWidth(); x += ROOM_RESOLUTION) {
      currentMapIndex = x + y * context.depthWidth();

      if (depthMap[currentMapIndex] > 1) {
        currentPoint = PVector.mult(realWorldDepthMap[currentMapIndex], 0.001);
        currentPointIntensity = cumulatedImpulseIntensityAtPosition(currentPoint);

        int r = 255;
        int g = 255;
        int b = 255;

        if (USE_COLOR_IMAGE) {
          currentPointColor = rgbImage.pixels[currentMapIndex];
          r = (currentPointColor >> 16) & 0xFF; // Faster way of getting red(argb)
          g = (currentPointColor >> 8) & 0xFF; // Faster way of getting green(argb)
          b = currentPointColor & 0xFF;
        }

        if (currentPointIntensity <= 0.1) {
          currentPointColor = color(r, g, b, 10.0 * map(currentPoint.z, .0, MAX_Z_DEPTH, 1.0, 0.1));
          stroke(currentPointColor);
          
          vertex(
            currentPoint.x + random(-STANDARD_SHIFT, STANDARD_SHIFT),
            currentPoint.y + random(-STANDARD_SHIFT, STANDARD_SHIFT),
            currentPoint.z + random(-STANDARD_SHIFT, STANDARD_SHIFT)
          );
        } 
        else {
          float alphaValue = map(currentPointIntensity, 0, 1.0, 0, 255) * map(currentPoint.z, .0, MAX_Z_DEPTH, 1.0, 0.1);
          currentPointColor = color(r, g, b, alphaValue);
          stroke(currentPointColor);

          float currentPointFrequence = cumulatedImpulseFrequenceAtPosition(currentPoint); 

          float maxFrequenceShift = currentPointFrequence / MAX_FREQUENCE_INDEX * BLUR_SHIFT;

          float intensityOffset = map(currentPointIntensity, 0.0, 1.0, STANDARD_SHIFT, MAX_FREQUENCE_INDEX);
          intensityOffset = constrain(intensityOffset,0.0,1.0);
          vertex(
            currentPoint.x + random(-intensityOffset, intensityOffset),
            currentPoint.y + random(-intensityOffset, intensityOffset),
            currentPoint.z + random(-intensityOffset, intensityOffset)
          );
        }
      }
    }
  }

  endShape();
  popMatrix();
}

/* Processing Callbacks */

boolean sketchFullScreen() {
  return RUN_FULLSCREEN;
}     

void keyPressed() {
  switch(key) {
  case ' ': // switch mirror
    context.setMirror(!context.mirror());
    break;
  case 'q': // reset oculus orientation
    oculus.resetOrientation();
    break;
  case 'w': // add new impulse from center
    addNewImpulse(new PVector(0, 0, 0), 1.0, 0);
    break;
  }
}
