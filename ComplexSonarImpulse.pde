class ComplexSonarImpulse {
  float speed = 0.25f; // m/s
  PVector origin = new PVector(0, 0, 0);
  float  originalIntensity = 1.0f;
  float intensity = 1.0f;
  float radius = 0.0f;
  float maxRadius = 50.0f;
  float waveLength = 20.0f; // meters
  float lengthWithMaxIntensity = 2.0f;
  float halfWaveLength = 2.0f;
  boolean delet = false;
  int lastTime = 0;

  ComplexSonarImpulse(PVector _position, float _originalIntensity) {
    radius = 1.0f;
    origin = _position;
    originalIntensity = _originalIntensity;
    halfWaveLength = waveLength * 0.5f;
    lastTime = millis();
  }

  void travelWave() {
    if (radius <= maxRadius) {
      int time = millis() - lastTime;
      radius += time*0.001 * speed;
    }
    else {
      delet = true;
    }
    //intensity = originalIntensity/sq(radius);
    intensity = originalIntensity;
  }


  float intensityAtPosition(PVector _position) {
    float intens = 0.0f;  

    // add faster calculation with squarecalculation !!!
    float d = PVector.dist(_position, origin);
    float dAbs = abs(d);
    if (dAbs > (radius - waveLength) &&  dAbs < radius) {
      //floatDistanceFromWave = radius - dAbs)/halfWaveLength;
      if (radius - dAbs < lengthWithMaxIntensity) {
        intens = map(radius - dAbs, 0f, lengthWithMaxIntensity, intensity, 0.3f);
      }
      else { 
        intens = map(radius - dAbs, 0f, waveLength, 0.3f, 0.1f);
      }
      return intens;
    }
    else return 0.0f;
  }
}

