import processing.sound.*;
import processing.sound.MultiChannel;

Sound sound;
AudioSample[] cvChannels = new AudioSample[16];  // dummy samples for each channel
float[] phases = new float[16];                  // phase for each CV channel
float[] cvValues = new float[16];                // current float values
float lfoFreq = 0.01;                            // very slow CV (~0.01 Hz)
int sampleRate = 44100;
int bufferSize = 64;                             // small buffer

void setup() {
  size(960, 400);
  textSize(14);

  MultiChannel.usePortAudio();
  sound = new Sound(this);

 // --- Select BlackHole ---
int devIndex = -1;
String[] devices = Sound.list();
for (int i = 0; i < devices.length; i++) {
  if (devices[i].toLowerCase().contains("blackhole")) {
    devIndex = i;
    break;
  }
}
if (devIndex != -1) {
  println("Using device: " + devices[devIndex]);
  Sound.outputDevice(devIndex);  // static call
} else {
  println("BlackHole not found!");
}


  // --- Create dummy AudioSamples for each channel ---
  for (int i = 0; i < 16; i++) {
    // 1-second dummy sample at 44100 Hz
    cvChannels[i] = new AudioSample(this, bufferSize);
    phases[i] = random(TWO_PI);

    MultiChannel.activeChannel(i);  // route this sample to channel i
    cvChannels[i].play();           // start playing
  }
}

void draw() {
  background(0);
  float deltaTime = 1.0 / frameRate;

  for (int i = 0; i < 16; i++) {
    // --- calculate CV value manually (-1..1) ---
    phases[i] += TWO_PI * lfoFreq * deltaTime;
    if (phases[i] > TWO_PI) phases[i] -= TWO_PI;
    cvValues[i] = sin(phases[i]);

    // --- Fill dummy buffer with the CV value ---
    float[] buffer = new float[bufferSize];
    for (int j = 0; j < bufferSize; j++) {
      buffer[j] = cvValues[i];  // constant value = CV
    }

    // --- update sample and send to audio output ---
    MultiChannel.activeChannel(i);
for (int j = 0; j < bufferSize; j++) {
    cvChannels[i].write(j, cvValues[i]);
}
    // --- visualization ---
    float x = map(cvValues[i], -1, 1, 0, width);
    stroke(255);
    line(0, 25 + i * 22, x, 25 + i * 22);
    fill(180);
    text("CV CH " + (i+1) + ": " + nf(cvValues[i],1,4), 10, 20+i*22);
  }
}
