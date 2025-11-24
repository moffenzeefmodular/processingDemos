// -------------------------------------------------------------
// TRUE CENTERED HARDWARE UI LAYOUT
// Screen = 960 x 400 (real size)
// Everything calculated from true center point
// -------------------------------------------------------------

int screenW = 960;
int screenH = 400;

int buttonSize = 55;
int encoderSize = 150;
int padSize = 150;

void setup() {
  size(1500, 1000);
  rectMode(CENTER);
  ellipseMode(CENTER);
  noStroke();
}

void draw() {
  background(25);

  // -------------------------------------------------------------
  // TRUE CENTER POINT OF ENTIRE DEVICE
  // -------------------------------------------------------------
  float cx = width / 2.0;
  float cy = height / 2.0;

  // -------------------------------------------------------------
  // PANEL SIZE (set generous margins so nothing clips)
  // -------------------------------------------------------------
  float panelW = screenW + 260;
  float panelH = screenH + 440;

  fill(32);
  rect(cx, cy, panelW, panelH, 25);

  // -------------------------------------------------------------
  // SCREEN (centered)
  // -------------------------------------------------------------
  float screenY = cy - panelH/2 + 50 + screenH/2;

  fill(0);
  rect(cx, screenY, screenW, screenH, 8);

  // -------------------------------------------------------------
  // BUTTON ROW (centered)
  // -------------------------------------------------------------
  float buttonRowY = screenY + screenH/2 + 70;

  // Evenly spaced buttons across the screen width
  float spacing = screenW / 5.0;
  float firstButtonX = cx - screenW/2 + spacing;

  color[] btnColors = {
    color(220, 50, 50),  // red
    color(140),
    color(180),
    color(180)
  };

  for (int i = 0; i < 4; i++) {
    fill(btnColors[i]);
    ellipse(firstButtonX + i * spacing, buttonRowY, buttonSize, buttonSize);
  }

  // -------------------------------------------------------------
  // ENCODERS (properly centered left & right)
  // -------------------------------------------------------------
  float encY = buttonRowY + 150;

  float leftEncX  = cx - screenW/4;
  float rightEncX = cx + screenW/4;

  fill(45);
  ellipse(leftEncX, encY, encoderSize, encoderSize);
  ellipse(rightEncX, encY, encoderSize, encoderSize);

  // Encoder indicator lines
  stroke(255);
  strokeWeight(4);
  float r = encoderSize * 0.42;
  float angle = -HALF_PI;

  line(leftEncX, encY, leftEncX + cos(angle)*r, encY + sin(angle)*r);
  line(rightEncX, encY, rightEncX + cos(angle)*r, encY + sin(angle)*r);

  noStroke();

  // -------------------------------------------------------------
  // XY PAD (centered between encoders)
  // -------------------------------------------------------------
  float padX = cx;
  float padY = encY + 10;

  pushMatrix();
  translate(padX, padY);
  rotate(radians(45));
  fill(65);
  rect(0, 0, padSize, padSize, 10);
  popMatrix();
}
