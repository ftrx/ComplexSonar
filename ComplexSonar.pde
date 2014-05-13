import SimpleOculusRift.*;
import SimpleOpenNI.*;

SimpleOpenNI context;
SimpleOculusRift oculusRiftDev;

boolean fullScreen = true; // false

//Kinect
int[] depthMap;
float rotY = 90.0f;


ArrayList sonars = new ArrayList<ComplexSonarImpulse>();

PMatrix3D formx = new PMatrix3D();
void setup()
{
  if (fullScreen) {
    size(1280, 800, OPENGL);
  }
   else {
    size(1280, 800, OPENGL);
  }

  oculusRiftDev = new SimpleOculusRift(this, SimpleOculusRift.RenderQuality_Middle); 
  oculusRiftDev.setBknColor(0, 0, 0);  // just not total black, to see the barr el distortion

  strokeWeight(.3);

  context = new SimpleOpenNI(this, SimpleOpenNI.RUN_MODE_MULTI_THREADED);

  if (context.isInit() == false) {
    println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
    exit();
    return;
  }

  context.setMirror(true); 
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
  PMatrix3D headOrientationMatrix = oculusRiftDev.headOrientationMatrix();

  formx = new PMatrix3D();
  formx.apply(headOrientationMatrix); 
  formx.rotateY(radians(180));
  formx.translate(0, 0, -1);

  context.update();
  depthMap = context.depthMap();

  oculusRiftDev.draw();
} 

void onDrawScene(int eye)
{  
  PVector realWorldPoint;
  PVector realWorldPointMilimeter; 
  int     steps = 4;
  int     index;
  color   pixelColor;

  PImage  rgbImage = context.rgbImage();

  pushMatrix();
  applyMatrix(formx);
  // rotate(radians(180));
  //translate(0,0,-300);

  strokeWeight((float)steps/2.0);


  ComplexSonarImpulse impulse;
  impulse = null;
  for (int i = 0; i< sonars.size(); i++)
  {
    impulse = (ComplexSonarImpulse)sonars.get(i);
    impulse.travelWave();
    if (impulse.delet)
    {
      sonars.remove(i);
      i--;
    }
  }


  PVector[] realWorldMap = context.depthMapRealWorld();

  float pointIntensity = 0;

  beginShape(POINTS);
  for (int y=0;y < context.depthHeight();y+=steps)
  {
    for (int x=0;x < context.depthWidth();x+=steps)
    {
      index = x + y * context.depthWidth();
      if (depthMap[index] > 0)
      {

        realWorldPointMilimeter = realWorldMap[index];
        realWorldPoint = PVector.mult(realWorldPointMilimeter, 0.001f);
        pixelColor = color(0);
        pointIntensity = 0;
        if (sonars.size() > 0)
        {
          for (int i=0; i<sonars.size();i++)
          {
            impulse = (ComplexSonarImpulse)sonars.get(i);
            pointIntensity += impulse.intensityAtPosition(realWorldPoint);
          }
          //println(pointIntensity);
          pixelColor = color(map(pointIntensity, 0, 1.0f, 0, 255)* map(realWorldPoint.z, 0f, 10.0f, 1.0f, 0.5f));
          
          if (pointIntensity <= 0.1f)
          {
             pixelColor = color(40f * map(realWorldPoint.z, 0f, 10.0f, 1.0f, 0.5f));
          }
        }
        else
        {
          pixelColor = color(40f * map(realWorldPoint.z, 0f, 10.0f, 1.0f, 0.5f));
          //vertex(realWorldPoint.x, realWorldPoint.y, realWorldPoint.z);
        }
        
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
    oculusRiftDev.resetOrientation();
    break;
  case 'w':
    addNewImpulse(new PVector(0, 0, 0), 1.0f);
    break;
  }
}

void addNewImpulse(PVector pos, float intens)
{
  ComplexSonarImpulse son = new ComplexSonarImpulse(pos, intens);
  sonars.add(son);
}

PMatrix3D returnMatrixfromAngles(float x, float y, float z) {
  PMatrix3D matrix = new PMatrix3D();
  matrix.rotateY(y);
  matrix.rotateX(x);
  matrix.rotateZ(z);
  return matrix;
}

PVector oculusNormalVector(SimpleOculusRift oculusCam) {
  PVector orientation = new PVector();
  oculusRiftDev.sensorOrientation(orientation);
  PMatrix3D mat = returnMatrixfromAngles(orientation.y, orientation.x, orientation.z);
  PVector normal = mat.mult(new PVector(0, 0, -1), null);
  return normal;
}

