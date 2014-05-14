float cumulatedImpulseIntensityAtPosition(PVector point) {
  float cumulatedIntensity = 0;
  for (int i=0; i < impulses.size(); i++) {
    Impulse impulse = impulses.get(i);
    cumulatedIntensity += impulse.intensityAtPosition(point);
  }
  return cumulatedIntensity;
}

class Impulse {
  float speed = 0.25; // m/s
  PVector origin = new PVector(0, 0, 0);
  float originalIntensity = 1.0;
  float actualIntensity = 1.0;
  float radius = .0;
  float maxRadius = 50.0;
  float waveLength = 20.0; // meters
  float lengthWithMaxIntensity = 2.0;
  float halfWaveLength = 2.0;
  boolean delete = false;
  int lastTime = 0;

  Impulse(PVector position, float _originalIntensity) {
    radius = 1.0;
    origin = position;
    originalIntensity = _originalIntensity;
    halfWaveLength = waveLength * 0.5;
    lastTime = millis();
  }

  void travelWave() {
    if (radius <= maxRadius) {
      radius += (millis() - lastTime) * 0.001 * speed;
    } else {
      delete = true;
    }
    actualIntensity = originalIntensity;
  }

  float intensityAtPosition(PVector position) {
    float intensity = 0.0;
    float distance = abs(PVector.dist(position, origin));
    
    if (distance > (radius - waveLength) &&  distance < radius) {
      if (radius - distance < lengthWithMaxIntensity) {
        intensity = map(radius - distance, .0, lengthWithMaxIntensity, actualIntensity, 0.3);
      } else { 
        intensity = map(radius - distance, .0, waveLength, 0.3, 0.1);
      }
      return intensity;
    }
    
    return .0;
  }
}

