/* ----------------------------------------------------------------------------
 * Math3DHelpr
 * ----------------------------------------------------------------------------
 * A collection of functions to make 3d calc. more fun
 * ----------------------------------------------------------------------------
 * prog: Max Rheiner / IAD Zhdk / 2014
 * ----------------------------------------------------------------------------
 */


import javax.media.opengl.*;
import javax.media.opengl.glu.*;


// draws a simple coordinate system
void coordSys(float size)
{
  pushStyle();

  stroke(255, 0, 0);
  line(0, 0, 0, 
  size, 0, 0);

  stroke(0, 255, 0);
  line(0, 0, 0, 
  0, size, 0);

  stroke(0, 0, 255);
  line(0, 0, 0, 
  0, 0, size);

  popStyle();
}

void drawRay(PVector p, PVector dir)
{
  PVector rayLine = dir.get();
  rayLine.normalize();
  rayLine.mult(300);
  line(p.x, p.y, p.z, 
  rayLine.x, rayLine.y, rayLine.z);
}

void drawPlane(PVector p1, PVector p2, PVector p3, 
               float len, int repeat)
{
  repeat--;

  // p1 is the center
  PVector u = PVector.sub(p2, p1);
  u.normalize();
  PVector v = PVector.sub(p3, p1);
  v.normalize();
  PVector dirUp = u.cross(v);
  dirUp.normalize();

  // rectangular
  PVector dirV = u.cross(dirUp);
  dirV.normalize();

  PVector stepsU = PVector.mult(u, (float)len / (float)repeat);
  PVector stepsV = PVector.mult(dirV, (float)len / (float)repeat);

  PVector posU1 = PVector.add(PVector.mult(stepsU, -0.5f * repeat), PVector.mult(stepsV, -0.5f * repeat));
  PVector posU2 = PVector.add(PVector.mult(stepsU, -0.5f * repeat), PVector.mult(stepsV, 0.5f * repeat));

  PVector posV1 = PVector.add(PVector.mult(stepsU, -0.5f * repeat), PVector.mult(stepsV, -0.5f * repeat));
  PVector posV2 = PVector.add(PVector.mult(stepsU, 0.5f * repeat), PVector.mult(stepsV, -0.5f * repeat));

  posU1.add(p1);
  posU2.add(p1);
  posV1.add(p1);
  posV2.add(p1);

  // horz
  for (int i=0;i<repeat+1;i++)
  {
    line(posU1.x, posU1.y, posU1.z, 
         posU2.x, posU2.y, posU2.z);
    line(posV1.x, posV1.y, posV1.z, 
         posV2.x, posV2.y, posV2.z);

    posU1.add(stepsU);
    posU2.add(stepsU);

    posV1.add(stepsV);
    posV2.add(stepsV);
  }
}



// normal in z dir
PVector[] createCircle2PolyLine(float radius, int segments, int type, boolean closed)
{
  float step = (2 * PI) / segments;
  float angle = 0;
  PVector[] list = new PVector[closed ? segments+1 : segments];

  int i=0;
  for (;i<segments;i++)
  {
    list[i] = calcCircleSeg(angle, radius, type);
    angle += step;
  }

  if (closed)
    list[i] = calcCircleSeg(angle, radius, type);

  return list;
}

// type = 0 -> xy plane
// type = 1 -> xz plane
// type = 2 -> yz plane

PVector calcCircleSeg(float angle, float radius, int type)
{
  switch(type)
  {
  case 1:
    // xz plane
    return(new PVector(radius * cos(angle), 
    0, 
    radius * sin(angle)));
  case 2:
    // yz plane
    return(new PVector(0, 
    radius * cos(angle), 
    radius * sin(angle)));
  case 0:
  default:
    // xy
    return(new PVector(radius * cos(angle), 
    radius * sin(angle), 
    0));
  }
}

PVector getPlaneNormal(PVector p1, PVector p2, PVector p3)
{
  PVector u = PVector.sub(p2, p1);
  PVector v = PVector.sub(p3, p1);

  u.normalize();
  v.normalize();

  PVector ret = PVector.cross(u, v, null);
  ret.normalize();
  return ret;
}

void getCoordSys(PVector p1, PVector p2, PVector p3, 
PVector xAxis, PVector yAxis, PVector zAxis)
{
  PVector u = PVector.sub(p2, p1);
  PVector v = PVector.sub(p3, p1);

  u.normalize();
  v.normalize();

  xAxis.set(u);

  yAxis.set(PVector.cross(u, v, null));
  yAxis.normalize();

  zAxis.set(PVector.cross(xAxis, yAxis, null));
  zAxis.normalize();
  /* 
   println("---------");
   println("xAxis: " + xAxis);
   println("yAxis: " + yAxis);
   println("zAxis: " + zAxis);
   */
}

PMatrix3D getRotationMat(PVector p1, PVector p2, PVector p3)
{
  PVector xAxis = new PVector();
  PVector yAxis = new PVector();
  PVector zAxis = new PVector();

  // calc a clean coordsystem out of the triangle, based on the x-axis(p1-p2)
  getCoordSys(p1, p2, p3, 
  xAxis, yAxis, zAxis);

  PMatrix3D mat = new PMatrix3D();
  mat.translate(p1.x, p1.y, p1.z);  

  mat.m00 = xAxis.x;
  mat.m10 = xAxis.y;
  mat.m20 = xAxis.z;

  mat.m01 = yAxis.x;
  mat.m11 = yAxis.y;
  mat.m21 = yAxis.z;

  mat.m02 = zAxis.x;
  mat.m12 = zAxis.y;
  mat.m22 = zAxis.z;

  return mat;
}


public class PickHelpers
{
    // opengl
    protected GL               _gl;
    protected GLU              _glu;
    protected PGraphicsOpenGL  _gOpengl = null;

    public void init(PApplet parent)
    {
          _gOpengl = (PGraphicsOpenGL)parent.g;
    }

    ///////////////////////////////////////////////////////////////////////////
    // helper functions
    public void getHitRay(int pick2dX,int pick2dY,
                   PVector r1,PVector r2)
    {
        r1.set(unProject(pick2dX, pick2dY, 0));
        r2.set(unProject(pick2dX, pick2dY, 1));
    }

    public PVector unProject(float winX, float winY, float z)
    {
        if(_gOpengl == null)
            return new PVector();

                PGL context = _gOpengl.beginPGL();
/*
                _gl  = context.gl;
                _glu = context.glu;
*/
                _gl  = ((PJOGL) context).gl;
                _glu = ((PJOGL) context).glu;


        int viewport[] = new int[4];
        float[] proj=new float[16];
        float[] model=new float[16];

        _gl.glGetIntegerv(GL.GL_VIEWPORT, viewport, 0);
                // glGetFloatv doesn't work with the new processing
                proj = transformP5toGL(((PGraphicsOpenGL)g).projection);
                model = transformP5toGL(((PGraphicsOpenGL)g).modelview);

        float[] mousePosArr=new float[4];

        _glu.gluUnProject((float)winX, viewport[3]-(float)winY, (float)z,
                          model, 0, proj, 0, viewport, 0, mousePosArr, 0);

                _gOpengl.endPGL();

        return new PVector((float)mousePosArr[0], (float)mousePosArr[1], (float)mousePosArr[2]);
    }
}

public static float[] transformP5toGL(PMatrix3D mat)
{
        float[] ret = new float[16];

        ret[0] = mat.m00;
    ret[1] = mat.m10;
    ret[2] = mat.m20;
    ret[3] = mat.m30;

    ret[4] = mat.m01;
    ret[5] = mat.m11;
    ret[6] = mat.m21;
    ret[7] = mat.m31;

    ret[8] = mat.m02;
    ret[9] = mat.m12;
    ret[10] = mat.m22;
    ret[11] = mat.m32;

    ret[12] = mat.m03;
    ret[13] = mat.m13;
    ret[14] = mat.m23;
    ret[15] = mat.m33;

        return ret;
}
