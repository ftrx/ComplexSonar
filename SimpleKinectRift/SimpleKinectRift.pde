/* --------------------------------------------------------------------------
 * SimpleOculusRift Basic
 * --------------------------------------------------------------------------
 * Processing Wrapper for the Oculus Rift
 * http://github.com/xohm/SimpleOculusRift
 * --------------------------------------------------------------------------
 * prog:  Max Rheiner / Interaction Design / Zhdk / http://iad.zhdk.ch/
 * date:  04/27/2014 (m/d/y)
 * ----------------------------------------------------------------------------
 * 1 unit should be 1m in the scene
 * ----------------------------------------------------------------------------
 */

import SimpleOculusRift.*;
import SimpleOpenNI.*;

SimpleOpenNI  context;


SimpleOculusRift   oculusRiftDev;

float   animRot = radians(45);


float floorDist = 1.7;


boolean   fullScreen = true;
//boolean   fullScreen = true;

// Raycast
PVector pRay = new PVector(0, 0, 0);
PVector pRayDir = new PVector(0, 0, -1);

int boxSize = 2;
PVector boxPosition;
PMatrix mat;

boolean intersects = false;

PVector orientation = new PVector();
PMatrix3D xform = new PMatrix3D();
color col_notSelected = color(255, 0, 0);
color col_selected = color(0, 255, 0);

PVector hit1 = new PVector();
PVector hit2 = new PVector();


//Kinect
int[]   depthMap;
float      rotY = 90.0f;
void setup()
{
  if (fullScreen)
    size(1280, 800, OPENGL);
  else    
    size(1280, 800, OPENGL);

  println("OPENGL_VERSION: " + PGraphicsOpenGL.OPENGL_VERSION);
  println("GLSL_VERSION: " + PGraphicsOpenGL.GLSL_VERSION);

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
  /*
  context.enableRGB();
  
  context.alternativeViewPointDepthToImage();
  context.setDepthColorSyncEnabled(true);
*/
}

void draw()
{
  animRot += 0.01;
  // calculate Ray
  oculusRiftDev.sensorOrientation(orientation);

  mat = returnMatrixfromAngles(orientation.y, orientation.x, orientation.z);
  pRayDir = mat.mult(new PVector(0, 0, -1), null);
  // println(orientation);   
  xform = new PMatrix3D();
  xform.translate(boxPosition.x, boxPosition.y, boxPosition.z);
  xform.rotate(animRot, 0, 1, 0);
  if (boxIntersection(xform, 
  pRay, 
  pRayDir, 
  new PVector(0, 0, 0), 
  boxSize, 
  boxSize, 
  boxSize, 
  hit1, hit2) > 0)
  {
    intersects = true;
  } 
  else {
    intersects = false;
  }

  /*
  // get the data of head tracking sensor
   PVector orientation = new PVector();
   oculusRiftDev.sensorOrientation(orientation);
   println(orientation);   
   */
  // kinect
  context.update();

  depthMap = context.depthMap();


  // draw the distortion on the screen
  oculusRiftDev.draw();
} 

// SimpleOculusRift call for drawing the scene for each eye
void onDrawScene(int eye)
{  
  /*
  //shows which eye is currently rendered
   if(eye == SimpleOculusRift.StereoEye_Left)
   println("draw left eye");
   else
   println("draw right eye");
   */
 /*
  stroke(200, 200, 220);
  fill(100, 100, 220);

  //drawGrid(new PVector(0, -floorDist, 0), 10, 10);

  // static box
  if (!intersects)
  {
    fill(col_notSelected);
  }
  else {
    fill(col_selected);
  }
  pushMatrix();

  //translate(boxPosition.x, boxPosition.y, boxPosition.z);
  applyMatrix(xform);

  box(boxSize);
  popMatrix();
  if (intersects)
  {
    strokeWeight(15);
    stroke(255, 255, 255);

    point(hit1.x, hit1.y, hit1.z);
    point(hit2.x, hit2.y, hit2.z);

    println(hit1);
    strokeWeight(1);
  }
  // fill(100,200,20);
*/

  /*
  fill(0,0,255);
   pushMatrix();
   //applyMatrix(mat);
   translate(pRayDir.x*5,pRayDir.y*5,pRayDir.z*5);
   sphere(1);
   popMatrix();
   */


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
        pixelColor =  color(map(realWorldPoint.z,0,10000,255,20));
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
  println("reset head orientation");
  oculusRiftDev.resetOrientation();

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

PMatrix returnMatrixfromAngles(float x, float y, float z)
{
  PMatrix3D matrix = new PMatrix3D();
  matrix.rotateY(y);
  matrix.rotateX(x);
  matrix.rotateZ(z);
  return matrix;
}

