int screenW = 960;
int screenH = 400;

int buttonSize = 55;
int encoderSize = 150;
int padSize = 150;
int padIndicatorSize = 20; // diameter of the indicator

// Encoder state
float leftEncAngle = -HALF_PI;
float rightEncAngle = -HALF_PI;

// Smoothed target angle
float leftEncTarget = leftEncAngle;
float rightEncTarget = rightEncAngle;

// Dragging info
int draggingEncoder = -1;
float lastMouseAngle = 0;

// Double-click timing
int[] lastClickTime = {0, 0};
boolean[] encoderPressed = {false, false};
int encoderPressDuration = 200; // ms

// ---------------------------
// Button state
// ---------------------------
boolean[] buttonPressed = new boolean[4];  // 4 buttons

// ---------------------------
// XY Pad Indicator
// ---------------------------
PVector padIndicator;
boolean draggingPad = false;

void setup() {
  size(1500, 1000);
  rectMode(CENTER);
  ellipseMode(CENTER);
  noStroke();

  // Initialize pad indicator at center
  padIndicator = new PVector(0, 0);
}

void draw() {
  background(255);

  float cx = width / 2.0;
  float cy = height / 2.0;
  float panelW = screenW + 260;
  float panelH = screenH + 440;

  fill(32);
  rect(cx, cy, panelW, panelH, 25);

  // SCREEN
  float screenY = cy - panelH/2 + 50 + screenH/2;
  fill(0);
  rect(cx, screenY, screenW, screenH, 8);

  // BUTTON ROW
  float buttonRowY = screenY + screenH/2 + 70;
  float spacing = screenW / 5.0;
  float firstButtonX = cx - screenW/2 + spacing;

  color[] baseColors = { color(220, 50, 50), color(140), color(180), color(180) };
  for (int i = 0; i < 4; i++) {
    color btnColor = buttonPressed[i] ? lerpColor(baseColors[i], color(0), 0.25) : baseColors[i];
    fill(btnColor);
    ellipse(firstButtonX + i * spacing, buttonRowY, buttonSize, buttonSize);

    // Centered inner shadow for depth
    noFill();
    stroke(0, 30);
    strokeWeight(4);
    ellipse(firstButtonX + i * spacing, buttonRowY, buttonSize * 0.9, buttonSize * 0.9);
    noStroke();
  }

  // ENCODERS
  float encY = buttonRowY + 150;
  float leftEncX  = cx - screenW/4;
  float rightEncX = cx + screenW/4;

  // Draw encoders with subtle pressed effect
  fill(encoderPressed[0] ? 38 : 45);
  ellipse(leftEncX, encY, encoderSize, encoderSize);
  fill(encoderPressed[1] ? 38 : 45);
  ellipse(rightEncX, encY, encoderSize, encoderSize);

  // Smooth rotation towards target (inertia)
  leftEncAngle += (leftEncTarget - leftEncAngle) * 0.2;
  rightEncAngle += (rightEncTarget - rightEncAngle) * 0.2;

  // Encoder indicator lines with subtle pressed effect
  strokeWeight(4);
  float knobRadius = encoderSize / 2.0;
  float indicatorLength = knobRadius * 0.2;

  // Left encoder line
  stroke(encoderPressed[0] ? color(200) : 255); // slightly darker if pressed
  float startX = leftEncX + cos(leftEncAngle) * (knobRadius - indicatorLength);
  float startY = encY + sin(leftEncAngle) * (knobRadius - indicatorLength);
  float endX   = leftEncX + cos(leftEncAngle) * knobRadius;
  float endY   = encY + sin(leftEncAngle) * knobRadius;
  line(startX, startY, endX, endY);

  // Right encoder line
  stroke(encoderPressed[1] ? color(200) : 255);
  startX = rightEncX + cos(rightEncAngle) * (knobRadius - indicatorLength);
  startY = encY + sin(rightEncAngle) * (knobRadius - indicatorLength);
  endX   = rightEncX + cos(rightEncAngle) * knobRadius;
  endY   = encY + sin(rightEncAngle) * knobRadius;
  line(startX, startY, endX, endY);

  noStroke();

  // XY PAD
  float padX = cx;
  float padY = encY + 10;
  pushMatrix();
  translate(padX, padY);
  rotate(radians(45));
  fill(65);
  rect(0, 0, padSize, padSize, 10);

  // Draw indicator dot as blue stroke
  noFill();
  stroke(0, 0, 255);
  strokeWeight(3);
  ellipse(padIndicator.x, padIndicator.y, padIndicatorSize, padIndicatorSize);
  noStroke();
  popMatrix();

  // Reset encoder press effect after duration
  for (int i = 0; i < 2; i++) {
    if (encoderPressed[i] && millis() - lastClickTime[i] > encoderPressDuration) {
      encoderPressed[i] = false;
    }
  }
}

// ---------------------------
// MOUSE INTERACTION
// ---------------------------
void mousePressed() {
  float cx = width / 2.0;
  float cy = height / 2.0;
  float screenY = cy - (screenH + 440)/2 + 50 + screenH/2;
  float buttonRowY = screenY + screenH/2 + 70;
  float encY = buttonRowY + 150;
  float leftEncX  = cx - screenW/4;
  float rightEncX = cx + screenW/4;

  // Check buttons
  float spacing = screenW / 5.0;
  float firstButtonX = cx - screenW/2 + spacing;
  for (int i = 0; i < 4; i++) {
    if (dist(mouseX, mouseY, firstButtonX + i * spacing, buttonRowY) < buttonSize/2) {
      buttonPressed[i] = true;
    }
  }

  // Check encoders for double-click
  for (int i = 0; i < 2; i++) {
    float encX = (i == 0) ? leftEncX : rightEncX;
    if (dist(mouseX, mouseY, encX, encY) < encoderSize/2) {
      int now = millis();
      if (now - lastClickTime[i] < 400) { // double click threshold
        encoderPressed[i] = true;         // trigger subtle press
      }
      lastClickTime[i] = now;
      draggingEncoder = i;
      lastMouseAngle = atan2(mouseY - encY, mouseX - encX);
    }
  }

  // Check XY pad click
  float padXc = cx;
  float padYc = encY + 10;
  float relX = (mouseX - padXc) * cos(radians(-45)) - (mouseY - padYc) * sin(radians(-45));
  float relY = (mouseX - padXc) * sin(radians(-45)) + (mouseY - padYc) * cos(radians(-45));
  float maxPos = padSize/2 - padIndicatorSize/2;
  if (abs(relX) <= padSize/2 && abs(relY) <= padSize/2) {
    draggingPad = true;
    padIndicator.x = constrain(relX, -maxPos, maxPos);
    padIndicator.y = constrain(relY, -maxPos, maxPos);
  }
}

void mouseDragged() {
  // Encoders
  if (draggingEncoder != -1) {
    float cx = width / 2.0;
    float cy = height / 2.0;
    float screenY = cy - (screenH + 440)/2 + 50 + screenH/2;
    float buttonRowY = screenY + screenH/2 + 70;
    float encY = buttonRowY + 150;
    float encX = (draggingEncoder == 0) ? cx - screenW/4 : cx + screenW/4;

    float currentMouseAngle = atan2(mouseY - encY, mouseX - encX);
    float delta = currentMouseAngle - lastMouseAngle;
    if (delta > PI) delta -= TWO_PI;
    if (delta < -PI) delta += TWO_PI;

    if (draggingEncoder == 0) leftEncTarget += delta;
    else rightEncTarget += delta;

    lastMouseAngle = currentMouseAngle;
  }

  // XY pad indicator
  if (draggingPad) {
    float cx = width / 2.0;
    float cy = height / 2.0;
    float buttonRowY = cy - (screenH + 440)/2 + 50 + screenH/2 + screenH/2 + 70;
    float padXc = cx;
    float padYc = buttonRowY + 150 + 10;

    float relX = (mouseX - padXc) * cos(radians(-45)) - (mouseY - padYc) * sin(radians(-45));
    float relY = (mouseX - padXc) * sin(radians(-45)) + (mouseY - padYc) * cos(radians(-45));

    float maxPos = padSize/2 - padIndicatorSize/2;
    padIndicator.x = constrain(relX, -maxPos, maxPos);
    padIndicator.y = constrain(relY, -maxPos, maxPos);
  }
}

void mouseReleased() {
  draggingEncoder = -1;
  draggingPad = false;
  for (int i = 0; i < 4; i++) buttonPressed[i] = false;
}
