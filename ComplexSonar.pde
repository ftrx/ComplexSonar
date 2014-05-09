import SimpleOculusRift.*;
import SimpleOpenNI.*;

SimpleOpenNI context;
SimpleOculusRift oculusRiftDev;

boolean fullScreen = true; // false

// Raycast
PVector pRay = new PVector(0, 0, 0);
PVector pRayDir = new PVector(0, 0, -1);

int boxSize = 2;
PVector boxPosition;

//Kinect
int[]   depthMap;
float      rotY = 90.0f;
void setup()
{
  if (fullScreen)
    size(1280, 800, OPENGL);
  else    
    size(1280, 800, OPENGL);

  oculusRiftDev = new SimpleOculusRift(this); 
  oculusRiftDev.setBknColor(10, 13, 2);  // just not total black, to see the barr el distortion

  strokeWeight(.3);

  boxPosition = new PVector(-3, -floorDist + 1, 0);

  // kinect
  //context = new SimpleOpenNI(this, SimpleOpenNI.RUN_MODE_MULTI_THREADED);
  context = new SimpleOpenNI(this);
  if (context.isInit() == false)
  {
    println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
    exit();
    return;
  }
  // mirror is by default enabled
  context.setMirror(false);

  // enable depthMap generation 
  context.enableDepth();
}

void draw()
{ 
  /*
  // get the data of head tracking sensor
   PVector orientation = new PVector();
   oculusRiftDev.sensorOrientation(orientation);
   println(orientation);   
   */
  // kinect
  context.update();

  depthMap = context.depthMap();

  oculusRiftDev.draw();
} 

// SimpleOculusRift call for drawing the scene for each eye
void onDrawScene(int eye)
{  
  PVector realWorldPoint;
  int     steps   = 4;  // to speed up the drawing, draw every third point
  int     index;
  color   pixelColor;

  PImage  rgbImage = context.rgbImage();

  pushMatrix();
  rotateY(radians(180));
  translate(0, 0, -300);
  strokeWeight((float)steps);

  PVector[] realWorldMap = context.depthMapRealWorld();

  beginShape(POINTS);
  for (int y=0;y < context.depthHeight();y+=steps)
  {
    for (int x=0;x < context.depthWidth();x+=steps)
    {
      index = x + y * context.depthWidth();
      if (depthMap[index] > 0)
      {
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

boolean sketchFullScreen() 
{
  return fullScreen;
}     

void keyPressed()
{
  switch(key)
  {
  case ' ':
    context.setMirror(!context.mirror());
    break;

  case 'q':
    println("reset head orientation");
    oculusRiftDev.resetOrientation();
    break;
  }
}

void drawGrid(PVector center, float length, int repeat)
{
  pushMatrix();

  translate(center.x, center.y, center.z);
  float pos;

  for (int x=0; x < repeat+1;x++)
  {
    pos = -length *.5 + x * length / repeat;

    line(-length*.5, 0, pos, 
    length*.5, 0, pos);

    line(pos, 0, -length*.5, 
    pos, 0, length*.5);
  }

  popMatrix();
}


//calculate rotationMatrix from angle
PMatrix returnMatrixfromAngles(float x, float y, float z)
{
  PMatrix3D matrix = new PMatrix3D();

  // this is specifcly for the simpleOculusRift, for other uses the order of rotation may be different (x,y,z or z,y,x etc)
  matrix.rotateY(y);
  matrix.rotateX(x);
  matrix.rotateZ(z);
  return matrix;
}


// Returns normal vector of the cculus cam
PVector oculusNormalVector(SimpleOculusRift oculusCam)
{
  PVector orientation = new PVector();
  oculusRiftDev.sensorOrientation(orientation);
  PMatrix3D mat = returnMatrixfromAngles(orientation.y, orientation.x, orientation.z);
  PVector normal = mat.mult(new PVector(0, 0, -1), null);
  return normal;
}

