/* ----------------------------------------------------------------------------
 * Math3DIntersections
 * ----------------------------------------------------------------------------
 * A collection of functions to make 3d calc. more fun
 * ----------------------------------------------------------------------------
 * prog: Max Rheiner / IAD Zhdk / 2014
 * ----------------------------------------------------------------------------
 */
 
 // Code adapted from Paul Bourke:
// http://local.wasp.uwa.edu.au/~pbourke/geometry/sphereline/raysphere.c
boolean circleLineIntersect(float x1, float y1, float x2, float y2, float cx, float cy, float cr ) 
{
  float dx = x2 - x1;
  float dy = y2 - y1;
  float a = dx * dx + dy * dy;
  float b = 2 * (dx * (x1 - cx) + dy * (y1 - cy));
  float c = cx * cx + cy * cy;
  c += x1 * x1 + y1 * y1;
  c -= 2 * (cx * x1 + cy * y1);
  c -= cr * cr;
  float bb4ac = b * b - 4 * a * c;

  //println(bb4ac);

  if (bb4ac < 0) {  // Not intersecting
    return false;
  }
  else {

    float mu = (-b + sqrt( b*b - 4*a*c )) / (2*a);
    float ix1 = x1 + mu*(dx);
    float iy1 = y1 + mu*(dy);
    mu = (-b - sqrt(b*b - 4*a*c )) / (2*a);
    float ix2 = x1 + mu*(dx);
    float iy2 = y1 + mu*(dy);

    // The intersection points
    //ellipse(ix1, iy1, 10, 10);
    //ellipse(ix2, iy2, 10, 10);

    float testX;
    float testY;
    // Figure out which point is closer to the circle
    if (dist(x1, y1, cx, cy) < dist(x2, y2, cx, cy)) {
      testX = x2;
      testY = y2;
    } 
    else {
      testX = x1;
      testY = y1;
    }

    if (dist(testX, testY, ix1, iy1) < dist(x1, y1, x2, y2) || dist(testX, testY, ix2, iy2) < dist(x1, y1, x2, y2)) {
      return true;
    } 
    else {
      return false;
    }
  }
}

int calcCircleIntersection(float x1, float y1, float r1, 
                           float x2, float y2, float r2, 
                           PVector res1, PVector res2)
{    
  float d = dist(x1, y1, x2, y2);
  if (d > (r1 + r2))
  {  // no intersection
    return 0;
  }

  /*
    else if((d - (r1 + r2)) < 0.0001)
   {
   res1.set(0,0,0);
   return 1;  
   }
   */

  float a = (sq(r1) - sq(r2) + sq(d)) / (2*d);
  float h = sqrt( sq(r1) - a*a );
  float valX = x1 + a*(x2 - x1)/d;
  float valY = y1 + a*(y2 - y1)/d;

  float paX = valX + h*(y2 - y1)/d;
  float paY = valY - h*(x2 - x1)/d;
  float pbX = valX - h*(y2 - y1)/d;
  float pbY = valY + h*(x2 - x1)/d;

  res1.set(paX, paY, 0);
  res2.set(pbX, pbY, 0);

  return 2;
}

int planeLineIntersection(PVector p1,PVector p2, 
                          PVector pPlane,PVector nPlane,
                          PVector hit)
{
    PVector   u = PVector.sub(p2,p1);
    PVector   w = PVector.sub(p1,pPlane);

    float     D = PVector.dot(nPlane, u);
    float     N = -PVector.dot(nPlane, w);

    if (abs(D) < 0.00000001) 
    {           // segment is parallel to plane
        if (N == 0)                      // segment lies in plane
            return 2;
        else
            return 0;                    // no intersection
    }
    
    // they are not parallel
    // compute intersect param
    float sI = N / D;
    if (sI < 0 || sI > 1)
        return 0;                        // no intersection

    hit.set(PVector.add(p1,PVector.mult(u,sI)));                  // compute segment intersect point
   
    return 1;
}

int planePolyLineIntersection(PVector[] polyLine, 
                              PVector pPlane,PVector nPlane,
                              ArrayList<PVector> hitArray)
{
  if (polyLine.length < 2)
    return 0;

  int ret = 0;
  int hits;
  PVector hit = new PVector();

  for (int i=0;i < polyLine.length-1;i++)
  {
    hits =  planeLineIntersection(polyLine[i], polyLine[i+1], 
                                  pPlane, nPlane, 
                                  hit);
    if (hits == 1)
      hitArray.add(hit.get());      
  }                               
  return hitArray.size();  
}


int sphereLineIntersection(PVector p1, PVector p2, 
                           PVector center, float r, 
                           PVector hit1, PVector hit2) 
{ 
  int ret = 0;
  PVector[] hits = new PVector[2];
  hits[0] = hit1;
  hits[1] = hit2;


  float a =  sq(p2.x - p1.x) + sq(p2.y - p1.y) + sq(p2.z - p1.z); 
  float b =  2* ( (p2.x - p1.x)*(p1.x - center.x) + (p2.y - p1.y)*(p1.y - center.y) + (p2.z - p1.z)*(p1.z - center.z) ) ; 
  float c =  center.x*center.x + center.y*center.y + center.z*center.z + p1.x*p1.x + p1.y*p1.y + p1.z*p1.z - 2* ( center.x*p1.x + center.y*p1.y + center.z*p1.z ) - r*r ; 
  float i =  b * b - 4 * a * c; 

  if ( i < 0.0 ) 
    // no intersection 
    ret = 0; 
  else if ( i == 0.0 )
  { 
    // one intersection 

    float mu = -b/(2*a) ; 
    if (abs(mu) < 1.0)
    {
      hits[ret].x = p1.x + mu*(p2.x-p1.x); 
      hits[ret].y = p1.y + mu*(p2.y-p1.y); 
      hits[ret].z = p1.z + mu*(p2.z-p1.z);
      ret++;
    }
  } 
  else 
  { 
    // first intersection 
    float mu = (-b + sqrt( b*b - 4*a*c )) / (2*a); 
    if (mu < 1.0 && mu > 0.0)
    {
      hits[ret].x = p1.x + mu*(p2.x-p1.x); 
      hits[ret].y = p1.y + mu*(p2.y-p1.y); 
      hits[ret].z = p1.z + mu*(p2.z-p1.z); 
      ret++;
    }

    // second intersection 
    mu = (-b - sqrt(b*b - 4*a*c )) / (2*a); 
    if (mu < 1.0 && mu > 0.0)
    {
      hits[ret].x = p1.x + mu*(p2.x-p1.x); 
      hits[ret].y = p1.y + mu*(p2.y-p1.y); 
      hits[ret].z = p1.z + mu*(p2.z-p1.z); 
      ret++;
    }
  } 

  return ret;
}

int spherePolylineArrayIntersection(PVector[] polyLine, 
                                    PVector center, float r, 
                                    ArrayList<PVector> hitArray) 
{
  if (polyLine.length < 2)
    return 0;

  int ret = 0;
  int hits;
  PVector hit1 = new PVector();
  PVector hit2 = new PVector();

  for (int i=0;i < polyLine.length-1;i++)
  {
    hits =  sphereLineIntersection(polyLine[i], polyLine[i+1], 
    center, r, 
    hit1, hit2);
    if (hits > 0)
    {
      hitArray.add(hit1.get());      
      if (hits > 1)
        hitArray.add(hit2.get());
    }
  }                               
  return hitArray.size();
}    


// -----------------------------------------------------------------------


// this code is based on the paper from Tomas Möller and Ben Trumbore
// 'Fast, minimum storage ray-triangle intersection.'
// http://www.graphics.cornell.edu/pubs/1997/MT97.html

boolean triangleIntersection(PVector p,
                             PVector d,
                             PVector v0,
                             PVector v1,
                             PVector v2,
                             PVector hit)
{
    float a,f,u,v;
    PVector e1 = PVector.sub(v1,v0);
    PVector e2 = PVector.sub(v2,v0);

    PVector h = d.cross(e2);
    a = e1.dot(h);

    if (a > -0.00001f && a < 0.00001f)
        return false;

    f = 1.0f / a;
    PVector s = PVector.sub(p,v0);
    u = f * s.dot(h);

    if (u < 0.0f || u > 1.0f)
        return false;

    PVector q = s.cross(e1);
    v = f * d.dot(q);

    if (v < 0.0f || u + v > 1.0f)
        return false;

    float t = f * e2.dot(q);

    if (t > 0.00001f) // ray intersection
    {
        hit.set(PVector.add(p , PVector.mult(d,t)));
        return true;
    }
    else
        return false;

}

// code is based on the openprocessing code:
// http://www.openprocessing.org/sketch/45539
int sphereIntersection(PVector rayP,
                       PVector dir,
                       PVector sphereCenter,float sphereRadius,
                       PVector hit1, PVector hit2)
{
  PVector e = new PVector();
  e.set(dir);
  e.normalize();
  PVector h = PVector.sub(sphereCenter,rayP);
  float lf = e.dot(h);                      // lf=e.h
  float s = pow(sphereRadius,2) - h.dot(h) + pow(lf,2);   // s=r^2-h^2+lf^2
  if(s < 0.0)
      return 0;                    // no intersection points ?
  s = sqrt(s);                              // s=sqrt(r^2-h^2+lf^2)

  int result = 0;
  if(lf < s)                               // S1 behind A ?
  {
      if (lf+s >= 0)                          // S2 before A ?}
      {
        s = -s;                               // swap S1 <-> S2}
        result = 1;                           // one intersection point
      }
  }
  else
      result = 2;                          // 2 intersection points

  hit1.set(PVector.add(PVector.mult(e,lf-s), rayP));
  hit2.set(PVector.add(PVector.mult(e,lf+s), rayP));

  return result;
}

int sphereIntersection(PVector rayP,
                       PVector dir,
                       PVector sphereCenter,float sphereRadius,
                       PVector hit1, PVector hit2,
                       PVector hit1Normal, PVector hit2Normal)
{
  PVector e = new PVector();
  e.set(dir);
  e.normalize();
  PVector h = PVector.sub(sphereCenter,rayP);
  float lf = e.dot(h);                      // lf=e.h
  float s = pow(sphereRadius,2) - h.dot(h) + pow(lf,2);   // s=r^2-h^2+lf^2
  if(s < 0.0)
      return 0;                    // no intersection points ?
  s = sqrt(s);                              // s=sqrt(r^2-h^2+lf^2)

  int result = 0;
  if(lf < s)                               // S1 behind A ?
  {
      if (lf+s >= 0)                          // S2 before A ?}
      {
        s = -s;                               // swap S1 <-> S2}
        result = 1;                           // one intersection point
      }
  }
  else
      result = 2;                          // 2 intersection points

  hit1.set(PVector.add(PVector.mult(e,lf-s), rayP));
  hit2.set(PVector.add(PVector.mult(e,lf+s), rayP));

  hit1Normal.set(PVector.sub(hit1,sphereCenter));
  hit1Normal.normalize();
  
  hit2Normal.set(PVector.sub(hit2,sphereCenter));
  hit2Normal.normalize();

  return result;
}


///////////////////////////////////////////////////////////////////////////////
// plane

boolean planeIntersection(PVector rayP,
                       PVector rayDir,
                       PVector planePos,
                       PVector planeDir,
                       PVector hit)
{
    PVector planeP1 = planePos.get();
    PVector dir = planeDir.get();
    dir.normalize();

    PVector difNorm = new PVector();
    if(dir.x == 1.0f)
        difNorm.set(0,1,0);
    else if(dir.y == 1.0f)
        difNorm.set(1,0,0);
    else if(dir.z == 1.0f)
        difNorm.set(1,0,0);
    else
    {
        difNorm.set(1,1,1);
        difNorm.normalize();
    }

    PVector u = dir.cross(difNorm);
    u.normalize();
    PVector v = dir.cross(u);
    v.normalize();
    PVector planeP2 = PVector.add(planeP1, u);
    PVector planeP3 = PVector.add(planeP1, v);

    return planeIntersection(rayP,
                             rayDir,
                             planeP1,
                             planeP2,
                             planeP3,
                             hit);
}

boolean planeIntersection(PVector p,
                          PVector dir,
                          PVector p1,
                          PVector p2,
                          PVector p3,
                          PVector hit)
{
    PVector r1 = p.get();
    PVector r2 = PVector.add(r1,dir);

    PVector v1 = PVector.sub(p2,p1);
    PVector v2 = PVector.sub(p3,p1);
    PVector v3 = v1.cross(v2);

    PVector vRotRay1 = new PVector( PVector.dot(v1, PVector.sub(r1,p1) ), PVector.dot(v2, PVector.sub(r1,p1) ), PVector.dot(v3, PVector.sub(r1,p1) ) );
    PVector vRotRay2 = new PVector( PVector.dot(v1, PVector.sub(r2,p1) ), PVector.dot(v2, PVector.sub(r2,p1) ), PVector.dot(v3, PVector.sub(r2,p1) ) );
    // Return now if ray will never intersect plane (they're parallel)
    if (vRotRay1.z == vRotRay2.z)
      return false;

    // Find 2D plane coordinates (fX, fY) that the ray interesects with
    float fPercent = vRotRay1.z / (vRotRay2.z - vRotRay1.z);

    hit.set(PVector.mult(PVector.add(r1, PVector.sub(r1,r2)), fPercent));

    return true;
}

boolean quadIntersection(PVector p,
                         PVector d,
                         PVector p1,
                         PVector p2,
                         PVector p3,
                         PVector p4,
                         PVector hit)
{

    if( triangleIntersection(p,d,
                             p1,p2,p3,
                             hit))
        return true;
    else if( triangleIntersection(p,d,
                                  p3,p4,p1,
                                  hit))
        return true;

    return false;
}

int boxIntersection(PMatrix3D xform,
                    PVector p,
                    PVector dir,
                    PVector boxCenter,
                    float boxWidth,
                    float boxHeigth,
                    float boxDepth,
                    PVector hit1,PVector hit2,
                    PVector hit1Normal,PVector hit2Normal)
{
    float x2 = boxWidth *.5f;
    float y2 = boxHeigth *.5f;
    float z2 = boxDepth *.5f;

    PVector p1 = new PVector(-x2,y2,-z2);
    PVector p2 = new PVector(x2,y2,-z2);
    PVector p3 = new PVector(x2,y2,z2);
    PVector p4 = new PVector(-x2,y2,z2);

    PVector p5 = new PVector(-x2,-y2,-z2);
    PVector p6 = new PVector(x2,-y2,-z2);
    PVector p7 = new PVector(x2,-y2,z2);
    PVector p8 = new PVector(-x2,-y2,z2);


    p1 = xform.mult(PVector.add(p1, boxCenter),null);
    p2 = xform.mult(PVector.add(p2, boxCenter),null);
    p3 = xform.mult(PVector.add(p3, boxCenter),null);
    p4 = xform.mult(PVector.add(p4, boxCenter),null);
    p5 = xform.mult(PVector.add(p5, boxCenter),null);
    p6 = xform.mult(PVector.add(p6, boxCenter),null);
    p7 = xform.mult(PVector.add(p7, boxCenter),null);
    p8 = xform.mult(PVector.add(p8, boxCenter),null);

    PVector[] hit = new PVector[2];
    hit[0] = new PVector();
    hit[1] = new PVector();
    
    PVector[] hitNormal = new PVector[2];
    hitNormal[0] = new PVector();
    hitNormal[1] = new PVector();
    
    int hitCount = 0;

    // check top
    if(quadIntersection(p,
                        dir,
                        p1,p2,p3,p4,
                        hit[hitCount]))
    {
        hitNormal[hitCount] = getPlaneNormal(p1,p2,p3);
        hitCount++;
    }

    // check bottom
    if(quadIntersection(p,
                        dir,
                        p5,p8,p7,p6,
                        hit[hitCount]))
    {
        hitNormal[hitCount] = getPlaneNormal(p5,p8,p7);
        hitCount++;
    }

    // check front
    if(hitCount < 2 && quadIntersection(p,
                                        dir,
                                        p4,p3,p7,p8,
                                        hit[hitCount]))
    {
        hitNormal[hitCount] = getPlaneNormal(p4,p3,p7);
        hitCount++;
    }

    // check back
    if(hitCount < 2 && quadIntersection(p,
                                        dir,
                                        p1,p5,p6,p2,
                                        hit[hitCount]))
    {
        hitNormal[hitCount] = getPlaneNormal(p1,p5,p6);
        hitCount++;
    }

    // check left
    if(hitCount < 2 && quadIntersection(p,
                                        dir,
                                        p1,p4,p8,p5,
                                        hit[hitCount]))
    {
        hitNormal[hitCount] = getPlaneNormal(p1,p4,p8);
        hitCount++;
    }

    // check right
    if(hitCount < 2 && quadIntersection(p,
                                        dir,
                                        p2,p6,p7,p3,
                                        hit[hitCount]))
    {
        hitNormal[hitCount] = getPlaneNormal(p2,p6,p7);
        hitCount++;
    }

    if(hitCount > 0)
    {
        if(hitCount > 1)
        {
            float dist1 = PVector.sub(p,hit[0]).mag();
            float dist2 = PVector.sub(p,hit[1]).mag();
            
            if(dist1 < dist2)
            {
                hit1.set(hit[0]);
                hit2.set(hit[1]);

                hit1Normal.set(hitNormal[0]);
                hit2Normal.set(hitNormal[1]);
            }
            else
            {
                hit1.set(hit[1]);
                hit2.set(hit[0]);

                hit1Normal.set(hitNormal[1]);
                hit2Normal.set(hitNormal[0]);
            }

        }
        else
        {
            hit1.set(hit[0]);
            hit1Normal.set(hitNormal[0]);
        }
    }

    return hitCount;
}

int boxIntersection(PMatrix3D xform,
                    PVector p,
                    PVector dir,
                    PVector boxCenter,
                    float boxWidth,
                    float boxHeigth,
                    float boxDepth,
                    PVector hit1,PVector hit2)
{
    float x2 = boxWidth *.5f;
    float y2 = boxHeigth *.5f;
    float z2 = boxDepth *.5f;

    PVector p1 = new PVector(-x2,y2,-z2);
    PVector p2 = new PVector(x2,y2,-z2);
    PVector p3 = new PVector(x2,y2,z2);
    PVector p4 = new PVector(-x2,y2,z2);

    PVector p5 = new PVector(-x2,-y2,-z2);
    PVector p6 = new PVector(x2,-y2,-z2);
    PVector p7 = new PVector(x2,-y2,z2);
    PVector p8 = new PVector(-x2,-y2,z2);


    p1 = xform.mult(PVector.add(p1, boxCenter),null);
    p2 = xform.mult(PVector.add(p2, boxCenter),null);
    p3 = xform.mult(PVector.add(p3, boxCenter),null);
    p4 = xform.mult(PVector.add(p4, boxCenter),null);
    p5 = xform.mult(PVector.add(p5, boxCenter),null);
    p6 = xform.mult(PVector.add(p6, boxCenter),null);
    p7 = xform.mult(PVector.add(p7, boxCenter),null);
    p8 = xform.mult(PVector.add(p8, boxCenter),null);

    PVector[] hit = new PVector[2];
    hit[0] = new PVector();
    hit[1] = new PVector();
    
    int hitCount = 0;

    // check top
    if(quadIntersection(p,
                        dir,
                        p1,p2,p3,p4,
                        hit[hitCount]))
    {
        hitCount++;
    }

    // check bottom
    if(quadIntersection(p,
                        dir,
                        p5,p8,p7,p6,
                        hit[hitCount]))
    {
        hitCount++;
    }

    // check front
    if(hitCount < 2 && quadIntersection(p,
                                        dir,
                                        p4,p3,p7,p8,
                                        hit[hitCount]))
    {
        hitCount++;
    }

    // check back
    if(hitCount < 2 && quadIntersection(p,
                                        dir,
                                        p1,p5,p6,p2,
                                        hit[hitCount]))
    {
        hitCount++;
    }

    // check left
    if(hitCount < 2 && quadIntersection(p,
                                        dir,
                                        p1,p4,p8,p5,
                                        hit[hitCount]))
    {
        hitCount++;
    }

    // check right
    if(hitCount < 2 && quadIntersection(p,
                                        dir,
                                        p2,p6,p7,p3,
                                        hit[hitCount]))
    {
         hitCount++;
    }

    if(hitCount > 0)
    {
        if(hitCount > 1)
        {
            float dist1 = PVector.sub(p,hit[0]).mag();
            float dist2 = PVector.sub(p,hit[1]).mag();
            
            if(dist1 < dist2)
            {
                hit1.set(hit[0]);
                hit2.set(hit[1]);
            }
            else
            {
                hit1.set(hit[1]);
                hit2.set(hit[0]);
            }

        }
        else
        {
            hit1.set(hit[0]);
        }
    }

    return hitCount;
}

int boxIntersection(PVector p,
                    PVector dir,
                    PVector boxCenter,
                    float boxWidth,
                    float boxHeigth,
                    float boxDepth,
                    PVector hit1,PVector hit2,
                    PVector hit1Normal,PVector hit2Normal)
{   
    return boxIntersection(new PMatrix3D(),
                           p,
                           dir,
                           boxCenter,
                           boxWidth,
                           boxHeigth,
                           boxDepth,
                           hit1,hit2,
                           hit1Normal,hit2Normal);
}

