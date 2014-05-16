import SimpleOculusRift.*;
import SimpleOpenNI.*;
import ddf.minim.analysis.*;
import ddf.minim.*;

Minim minim;
AudioInput input;
FFT fft;
SimpleOpenNI context;
SimpleOculusRift oculus;

int SIGNAL_COOLDOWN_TIME = 500;
int ROOM_RESOLUTION = 8; // lower = better
boolean USE_COLOR_IMAGE = false; // does not work in completly dark environments
boolean RUN_FULLSCREEN = true;

float signalIntensity;
float lastWaveTime = .0;
boolean signalCooldown = true;

PImage rgbImage;
int[] depthMap;
PVector[] realWorldDepthMap;

ArrayList<Impulse> impulses = new ArrayList<Impulse>();

PMatrix3D headOrientation;
float maxZDepth = 7.0; // meters


float impulseThreshhold = 20.0;

float frequenceIndex = 0;
float blurShift = 0.08;
float standardShift = 0.06;
float maxFrequenceIndex = 4;


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

  minim = new Minim (this);
  input = minim.getLineIn(Minim.STEREO, 512);
  fft = new FFT(input.bufferSize(), input.sampleRate());
}

void draw() {
  headOrientation = oculus.headOrientationMatrix(); 
  headOrientation.rotateY(radians(180));
  headOrientation.translate(0, 0, -0.5);

  context.update();

  signalIntensity = input.mix.level() * 10.0;
  if (getLoudestFrequence(impulseThreshhold) > -1 && signalCooldown) {
    frequenceIndex = maxFrequenceIndex - getLoudestFrequence(impulseThreshhold); 
    //frequenceIndex = getLoudestFrequence(impulseThreshhold, input); 
    println(frequenceIndex);  
    addNewImpulse(new PVector(0, 0, 0), 1.0, int(frequenceIndex));
    if (frequenceIndex <= 0)
      frequenceIndex = 0;
    lastWaveTime = millis();
    signalCooldown = false;
  } 
  else if (millis() - lastWaveTime >= SIGNAL_COOLDOWN_TIME) {
    signalCooldown = true;
  }

  depthMap = context.depthMap();
  realWorldDepthMap = context.depthMapRealWorld();

  rgbImage = context.rgbImage();

  // getLoudestFrequence(1.0, input);
  
  oculus.draw();
} 

void onDrawScene(int eye) {
  pushMatrix();
  applyMatrix(headOrientation);

  strokeWeight((float)ROOM_RESOLUTION/2.0);

  updateImpulses();

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
          currentPointColor = color(r, g, b, 10.0 * map(currentPoint.z, .0, maxZDepth, 1.0, 0.1));
          stroke(currentPointColor);
          
          vertex(
            currentPoint.x + random(-standardShift, standardShift),
            currentPoint.y + random(-standardShift, standardShift),
            currentPoint.z + random(-standardShift, standardShift)
          );
        } 
        else {
          float alphaValue = map(currentPointIntensity, 0, 1.0, 0, 255) * map(currentPoint.z, .0, maxZDepth, 1.0, 0.1);
          currentPointColor = color(r, g, b, alphaValue);
          stroke(currentPointColor);

          float currentPointFrequence = cumulatedImpulseFrequenceAtPosition(currentPoint); 

          float maxFrequenceShift = currentPointFrequence / maxFrequenceIndex * blurShift;

          float intensityOffset = map(currentPointIntensity, 0.0, 1.0, standardShift, maxFrequenceShift);
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

void addNewImpulse(PVector pos, float intens, int frequence) {
  impulses.add(new Impulse(pos, intens, frequence));
}

int getLoudestFrequence(float threshold) {
  // calculate averages based on a miminum octave width of 22 Hz
  // split each octave into three bands
  // this should result in 30 averages
  fft.logAverages(22, 1);
  fft.forward(input.mix);
  
  int loudestFrequency = -1;
  float loudestAverage = 0.0f;

  for (int i=0; i < fft.avgSize(); i++) {
    float newAverage = fft.getAvg(i);
    if (loudestAverage < newAverage) {
      loudestAverage = newAverage;
      loudestFrequency = i;
    }
  }
  
  if (loudestAverage > threshold) {
    return loudestFrequency;
  } else {
    return -1;
  }    
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
