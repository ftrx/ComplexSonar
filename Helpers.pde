PMatrix3D returnMatrixfromAngles(float x, float y, float z) {
  PMatrix3D matrix = new PMatrix3D();
  matrix.rotateY(y);
  matrix.rotateX(x);
  matrix.rotateZ(z);
  return matrix;
}

int getLoudestFrequence(float threshold) {
  // calculate averages based on a miminum octave width of 22 Hz
  // split each octave into three bands
  // this should result in 30 averages
  fft.logAverages(22, 1);
  fft.forward(input.mix);
  
  int loudestFrequency = -1;
  float loudestAverage = 0.0f;

  for (int i=0; i < fft.avgSize(); i++) {
    float newAverage = fft.getAvg(i);
    if (loudestAverage < newAverage) {
      loudestAverage = newAverage;
      loudestFrequency = i;
    }
  }
  
  if (loudestAverage > threshold) {
    return loudestFrequency;
  } else {
    return -1;
  }    
}

