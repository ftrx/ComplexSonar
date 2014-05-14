import SimpleOculusRift.*;
import SimpleOpenNI.*;
import ddf.minim.*;

Minim minim;
AudioInput input;
SimpleOpenNI context;
SimpleOculusRift oculus;

int SIGNAL_COOLDOWN_TIME = 2000;
int ROOM_RESOLUTION = 8; // lower = better

float signalIntensity;
float lastWaveTime = .0;
boolean signalCooldown = true;

boolean fullScreen = true;

int[] depthMap;
PVector[] realWorldDepthMap;

ArrayList<Impulse> impulses = new ArrayList<Impulse>();

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

  minim = new Minim (this);
  input = minim.getLineIn(Minim.STEREO, 512);
}

void draw() {
  headOrientation = oculus.headOrientationMatrix(); 
  headOrientation.rotateY(radians(180));
  headOrientation.translate(0, 0, -0.5);

  context.update();

  signalIntensity = input.mix.level() * 10.0;
  if (signalIntensity > 1.0 && signalCooldown) {
    addNewImpulse(new PVector(0, 0, 0), 1.0);
    lastWaveTime = millis();
    signalCooldown = false;
  } 
  else if (millis() - lastWaveTime >= SIGNAL_COOLDOWN_TIME) {
    signalCooldown = true;
  }
  
  depthMap = context.depthMap();
  realWorldDepthMap = context.depthMapRealWorld();

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

        if (currentPointIntensity <= 0.1) {
          currentPointColor = color(10.0 * map(currentPoint.z, .0, 10.0, 1.0, 0.5));
        } else {
          currentPointColor = color(map(currentPointIntensity, 0, 1.0, 0, 255)* map(currentPoint.z, .0, 10.0, 1.0, 0.5));
        }

        stroke(currentPointColor);
        vertex(currentPoint.x, currentPoint.y, currentPoint.z);
      }
    }
  }
  
  endShape();
  popMatrix();
}

void addNewImpulse(PVector pos, float intens) {
  impulses.add(new Impulse(pos, intens));
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
    addNewImpulse(new PVector(0, 0, 0), 1.0);
    break;
  }
}

