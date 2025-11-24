import processing.sound.*;

Sound sound;        // <-- You MUST create this first
AudioIn[] ins = new AudioIn[16];
Amplitude[] amps = new Amplitude[16];
float[] level = new float[16];

void setup() {
  size(960, 400);
  background(0);
  textSize(14);

  // --- Create Sound engine BEFORE listing devices ---
  sound = new Sound(this);

  println("Audio devices:");
  String[] devices = Sound.list();
  println(devices);

  // --- Find BlackHole ---
  int blackholeIndex = -1;
  for (int i = 0; i < devices.length; i++) {
    if (devices[i].toLowerCase().contains("blackhole")) {
      blackholeIndex = i;
      break;
    }
  }

  if (blackholeIndex != -1) {
    println("✔ Selecting device: " + devices[blackholeIndex]);

    // IMPORTANT:
    // You must call *sound.inputDevice*, not Sound.inputDevice
    sound.inputDevice(blackholeIndex);
  } else {
    println("❌ BlackHole not found.");
  }

  delay(200); // macOS needs a short delay after device switch

  // --- Now create the inputs ---
  for (int i = 0; i < 16; i++) {
    ins[i] = new AudioIn(this, i);
    amps[i] = new Amplitude(this);
    ins[i].start();
    amps[i].input(ins[i]);
  }
}

void draw() {
  background(0);

  for (int i = 0; i < 16; i++) {
    level[i] = amps[i].analyze();

    float x = level[i] * width;

    stroke(255);
    line(0, 25 + i * 22, x, 25 + i * 22);

    fill(180);
    text("CH " + (i + 1) + ": " + nf(level[i], 1, 4), 10, 20 + i * 22);
  }
}
