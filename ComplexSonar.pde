import SimpleOculusRift.*;
import SimpleOpenNI.*;
import ddf.minim.analysis.*;
import ddf.minim.*;

Minim minim;
AudioInput input;
SimpleOpenNI context;
SimpleOculusRift oculus;

int SIGNAL_COOLDOWN_TIME = 100;
int ROOM_RESOLUTION = 8; // lower = better

float signalIntensity;
float lastWaveTime = .0;
boolean signalCooldown = true;

boolean fullScreen = true;

int[] depthMap;
PVector[] realWorldDepthMap;

boolean useColorImage = false; // does not work in completly dark environments
PImage rgbImage;

ArrayList<Impulse> impulses = new ArrayList<Impulse>();

PMatrix3D headOrientation;

float impulseThreshhold = 15.0;
int frequenceIndex = 0;
float blurShift = 0.04;
float standardShift = 0.08;
int maxFrequenceIndex = 5;

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
}

void draw() {
  headOrientation = oculus.headOrientationMatrix(); 
  headOrientation.rotateY(radians(180));
  headOrientation.translate(0, 0, -0.5);

  context.update();

  signalIntensity = input.mix.level() * 10.0;
  if (getLoudestFrequence(impulseThreshhold, input) > -1 && signalCooldown ) {
    frequenceIndex = maxFrequenceIndex - getLoudestFrequence(impulseThreshhold, input);   
    addNewImpulse(new PVector(0, 0, 0), 1.0, frequenceIndex);
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

        if (useColorImage) {
          currentPointColor = rgbImage.pixels[currentMapIndex];
          r = (currentPointColor >> 16) & 0xFF; // Faster way of getting red(argb)
          g = (currentPointColor >> 8) & 0xFF; // Faster way of getting green(argb)
          b = currentPointColor & 0xFF;
        }

        if (currentPointIntensity <= 0.1) {
          currentPointColor = color(r, g, b, 10.0 * map(currentPoint.z, .0, 5.0, 1.0, 0.1));
          stroke(currentPointColor);
          vertex(
            currentPoint.x + random(-standardShift, standardShift),
            currentPoint.y + random(-standardShift, standardShift),
            currentPoint.z + random(-standardShift, standardShift)
          );
        } 
        else {
          float alphaValue = map(currentPointIntensity, 0, 1.0, 0, 255) * map(currentPoint.z, .0, 5.0, 1.0, 0.1);
          currentPointColor = color(r, g, b, alphaValue);
          stroke(currentPointColor);
        
          float currentPointFrequence = cumulatedImpulseFrequenceAtPosition(currentPoint); 
          float maxFrequenceShift = currentPointFrequence / (float)maxFrequenceIndex * blurShift;
          float intensityOffset = map(currentPointIntensity, 0.0, 1.0, standardShift, maxFrequenceShift);
          
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

int getLoudestFrequence(float threshold, AudioInput in)
{
  FFT fft = new FFT(in.bufferSize(), in.sampleRate());
  // calculate averages based on a miminum octave width of 22 Hz
  // split each octave into three bands
  // this should result in 30 averages
  fft.logAverages(22, 1);
  fft.forward(in.mix);
  int loudestFrequency = -1;
  float strLoudestFrequency = 0.0f;
  float loudestAverage = 0.0f;
  float spectrumScale = 1;

  for (int i=0; i < fft.avgSize(); i++) {
    if (loudestAverage < fft.getAvg(i) * spectrumScale) {
      loudestAverage = fft.getAvg(i) * spectrumScale;
      strLoudestFrequency = fft.getAverageCenterFrequency(i);
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
  return fullScreen;
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
