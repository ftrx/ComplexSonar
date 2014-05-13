import SimpleOculusRift.*;
import SimpleOpenNI.*;

SimpleOpenNI context;
SimpleOculusRift oculus;

boolean fullScreen = true;

int[] depthMap;
float rotY = 90.0f;

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
  
  context.setMirror(false); 
  context.enableDepth();
}

void draw() {
  /*
  // get the data of head tracking sensor
  PVector orientation = new PVector();
  oculusRiftDev.sensorOrientation(orientation);
  println(orientation);   
  */
   
  context.update();
  depthMap = context.depthMap();

  oculus.draw();
} 

void onDrawScene(int eye) {
  PVector realWorldPoint;
  int     steps = 4;
  int     index;
  color   pixelColor;

  PImage  rgbImage = context.rgbImage();

  pushMatrix();
  rotateY(radians(180));
  translate(0, 0, -300);
  strokeWeight((float)steps);

  PVector[] realWorldMap = context.depthMapRealWorld();

  beginShape(POINTS);
  for (int y=0; y < context.depthHeight(); y += steps) {
    for (int x=0; x < context.depthWidth(); x += steps) {
      index = x + y * context.depthWidth();
      if (depthMap[index] > 0) {
        realWorldPoint = realWorldMap[index];
        pixelColor =  color(map(realWorldPoint.z, 0, 10000, 255, 20));
        stroke(pixelColor);
        vertex(realWorldPoint.x, realWorldPoint.y, realWorldPoint.z);
      }
    }
  }
  endShape();
  popMatrix();
}

boolean sketchFullScreen() {
  return fullScreen;
}     

void keyPressed() {
  switch(key) {
    case ' ':
      context.setMirror(!context.mirror());
      break;
    case 'q':
      println("reset head orientation");
      oculus.resetOrientation();
      break;
  }
}

PMatrix3D returnMatrixfromAngles(float x, float y, float z) {
  PMatrix3D matrix = new PMatrix3D();
  matrix.rotateY(y);
  matrix.rotateX(x);
  matrix.rotateZ(z);
  return matrix;
}

PVector oculusNormalVector() {
  PVector orientation = new PVector();
  oculus.sensorOrientation(orientation);
  PMatrix3D mat = returnMatrixfromAngles(orientation.y, orientation.x, orientation.z);
  PVector normal = mat.mult(new PVector(0, 0, -1), null);
  return normal;
}

