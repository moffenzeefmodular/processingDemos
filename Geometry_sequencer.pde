import oscP5.*;
import netP5.*;

OscP5 OSC;
float[] CV = new float[8];

final int MAX_SIDES = 32;

// --- main clock ---
Knob clockKnob;

// --- Sequencer array ---
Sequencer[] sequencers;

// ---------------- VertexDot ----------------
class VertexDot {
  float x, y;
  color baseCol = color(255);
  color targetCol = baseCol;
  color col = baseCol;

  VertexDot() {}

  void display(float size) {
    fill(col);
    noStroke();
    ellipse(x, y, size, size);
  }

  void toggle() { 
    baseCol = (baseCol == color(255)) ? color(255,255,0) : color(255); 
    targetCol = baseCol;
  }

  void resetColor() { targetCol = baseCol; }

  void updateColor() {
    float lerpAmt = 0.25;
    col = color(
      lerp(red(col), red(targetCol), lerpAmt),
      lerp(green(col), green(targetCol), lerpAmt),
      lerp(blue(col), blue(targetCol), lerpAmt)
    );
  }

  boolean isHit(float mx, float my, float dotSize) {
    return dist(mx,my,x,y) < dotSize/2;
  }
}

// ---------------- Knob ----------------
class Knob {
  float x, y, radius;
  boolean active = false;
  float value;
  String label;

  Knob(float x, float y, float radius, String label, float value){
    this.x = x; this.y = y; this.radius = radius;
    this.label = label; this.value = value;
  }

  void display(){
    fill(80);
    stroke(255);
    strokeWeight(2);
    ellipse(x, y, radius*2, radius*2);

    float angle = lerp(-3*PI/4 - PI/2, 3*PI/4 - PI/2, value);
    stroke(255); strokeWeight(3);
    line(x, y, x + cos(angle)*radius*0.8, y + sin(angle)*radius*0.8);

    noStroke(); fill(255); textAlign(CENTER, CENTER);
    text(label, x, y + radius + 15);

    String valStr = "";
    if(label.equals("Clock Speed")){
      float minInterval = 0.025;
      float maxInterval = 1.0;
      float interval = lerp(maxInterval, minInterval, value);
      valStr = int(interval*1000) + " ms";
    } else if(label.startsWith("Length")){
      int sides = int(map(value, 0, 1, 3, MAX_SIDES));
      valStr = sides + "";
    } else if(label.startsWith("Rotate")){
      int rot = int(map(value, 0, 1, 0, MAX_SIDES-1));
      valStr = rot + "";
    } else if(label.startsWith("Clk Divide")){
      int div = max(1,int(map(value,0,1,1,16)));
      valStr = "/"+div;
    }
    text(valStr, x, y + radius + 35);
  }

  boolean hit(float mx, float my){ return dist(mx, my, x, y) < radius; }

  void drag(float dy){
    value += -dy * 0.002;
    value = constrain(value, 0, 1);
  }
}

class Button {
  float x, y, radius;
  boolean wasPressed = false;
  float flashAlpha = 0;
  String label;

  Button(float x, float y, float radius, String label){
    this.x = x;
    this.y = y;
    this.radius = radius * 0.4; // half-size
    this.label = label;
  }

  void display(){
    // Draw base button (white)
    fill(255);
    noStroke();
    ellipse(x, y, radius*2, radius*2);

    // Overlay flash red if active
    if(flashAlpha > 0){
      fill(255,0,0, flashAlpha);
      ellipse(x, y, radius*2, radius*2);
      flashAlpha -= 5;          // fade out
      if(flashAlpha < 0) flashAlpha = 0;
    }

    // Draw label below button
    fill(255);
    textAlign(CENTER, TOP);
    text(label, x, y + radius + 5);
  }

  boolean hit(float mx, float my){
    return dist(mx, my, x, y) < radius;
  }

  void trigger(){ 
    flashAlpha = 255; // start flash
  }
}

// ---------------- Sequencer ----------------
class Sequencer {
  float centerX, centerY;
  VertexDot[] dots;
  int currentStep = -1;
  Knob sidesKnob, rotateKnob, clkDivideKnob;
  float stepTimer = 0;
  Button resetButton;

  Sequencer(float centerX, float centerY){
    this.centerX = centerX;
    this.centerY = centerY;
    dots = new VertexDot[MAX_SIDES];
    for(int i=0;i<MAX_SIDES;i++) dots[i] = new VertexDot();

    float knobY = height - 80; 
    float spacing = 80;

    clkDivideKnob = new Knob(centerX - spacing, knobY, 20, "Clk Divide", 0.0);
    sidesKnob     = new Knob(centerX, knobY, 20, "Length", 0.0);
    rotateKnob    = new Knob(centerX + spacing, knobY, 20, "Rotate", 0.0);

    // Reset button at center of polygon
    resetButton = new Button(centerX, centerY, 20, "Reset");
  }

  void update(float mainClockInterval){
    int sides = constrain(round(map(sidesKnob.value,0,1,3,MAX_SIDES)),3,MAX_SIDES);
    int rotIndex = floor(rotateKnob.value*(sides-1));
    int clkDivide = max(1, int(map(clkDivideKnob.value,0,1,1,16)));

    float interval = mainClockInterval * clkDivide;
    stepTimer += 1.0/frameRate;

    if(stepTimer >= interval){
      stepTimer = 0;
      currentStep = (currentStep + 1) % sides;
      if(currentStep != -1) dots[currentStep].resetColor();
    }

    float radius = min(width,height)*0.25;
    float angleStep = TWO_PI / sides;

    for(int i=0;i<sides;i++){
      float angle = i*angleStep - HALF_PI;
      dots[i].x = cos(angle)*radius;
      dots[i].y = sin(angle)*radius;
    }

    for(int i=0;i<sides;i++){
      int patternIndex = (i-rotIndex+sides)%sides;
      color dotBase = dots[patternIndex].baseCol;

      if(i == currentStep){
        if(dotBase == color(255,255,0)) dots[i].targetCol = color(0,255,0);
        else dots[i].targetCol = color(255,0,0);
      } else dots[i].targetCol = dotBase;

      dots[i].updateColor();
    }

    pushMatrix();
    translate(centerX, centerY);
    stroke(255); strokeWeight(2); noFill();
    beginShape();
    for(int i=0;i<sides;i++) vertex(dots[i].x,dots[i].y);
    endShape(CLOSE);

    float lineLength = radius*0.2;
    line(0,-radius-5,0,-radius-5-lineLength);

    float dotSize = radius*0.15;
    for(int i=0;i<sides;i++) dots[i].display(dotSize);
    popMatrix();

    clkDivideKnob.display();
    sidesKnob.display();
    rotateKnob.display();
    resetButton.display();
  }

  void handleMouse(float mx, float my){
    float radius = min(width,height)*0.25;
    int sides = constrain(round(map(sidesKnob.value,0,1,3,MAX_SIDES)),3,MAX_SIDES);
    int rotIndex = floor(rotateKnob.value*(sides-1));
    float adjX = mx - centerX;
    float adjY = my - centerY;
    float dotSize = radius*0.15;

    for(int i=0;i<sides;i++){
      int patternIndex = (i-rotIndex+sides)%sides;
      if(dots[i].isHit(adjX,adjY,dotSize)) dots[patternIndex].toggle();
    }

    // handle reset button rising edge
    if(resetButton.hit(mx,my) && !resetButton.wasPressed){
      resetButton.trigger(); // flash red
      currentStep = 0; // reset immediately
    }
    resetButton.wasPressed = resetButton.hit(mx,my);
  }
}

// ---------------- Setup ----------------
void setup() {
  size(960, 400);
  smooth();

  OSC = new OscP5(this,7000);
  for(int i=0;i<8;i++) OSC.plug(this,"CV"+(i+1)+"In","/ch/"+(i+1));

  float marginX = width/6;
  sequencers = new Sequencer[3];
  sequencers[0] = new Sequencer(marginX, height*0.45);
  sequencers[1] = new Sequencer(width/2, height*0.45);
  sequencers[2] = new Sequencer(width-marginX, height*0.45);

  // --- Initialize sequencers to 16 steps ---
  for(Sequencer seq : sequencers){
    seq.sidesKnob.value = map(16, 3, MAX_SIDES, 0, 1); // maps 16 steps to knob 0-1
  }

  // Move Clock speed knob to top right with margin and init to 100ms
  float knobMargin = 30;
  float knobRadius = 20;
  clockKnob = new Knob(width - knobMargin - knobRadius, knobMargin + knobRadius, knobRadius, "Clock Speed", 0.0);
  
  // Convert 100ms to knob value
  float minInterval = 0.025;
  float maxInterval = 1.0;
  float targetInterval = 0.1; // 100 ms
  clockKnob.value = map(targetInterval, maxInterval, minInterval, 0, 1);
}

// ---------------- Draw ----------------
void draw() {
  background(30);

  float minInterval = 0.025;
  float maxInterval = 1.0;
  float mainClockInterval = lerp(maxInterval, minInterval, clockKnob.value);

  for(Sequencer seq : sequencers){
    seq.update(mainClockInterval);
  }

  clockKnob.display();
}

// ---------------- Mouse ----------------
void mousePressed(){
  if(clockKnob.hit(mouseX, mouseY)) clockKnob.active = true;
  for(Sequencer seq : sequencers){
    if(seq.sidesKnob.hit(mouseX, mouseY)) seq.sidesKnob.active = true;
    if(seq.rotateKnob.hit(mouseX, mouseY)) seq.rotateKnob.active = true;
    if(seq.clkDivideKnob.hit(mouseX, mouseY)) seq.clkDivideKnob.active = true;
    seq.handleMouse(mouseX, mouseY);
  }
}

void mouseDragged(){
  float dy = mouseY - pmouseY;
  if(clockKnob.active) clockKnob.drag(dy);
  for(Sequencer seq : sequencers){
    if(seq.sidesKnob.active) seq.sidesKnob.drag(dy);
    if(seq.rotateKnob.active) seq.rotateKnob.drag(dy);
    if(seq.clkDivideKnob.active) seq.clkDivideKnob.drag(dy);
  }
}

void mouseReleased(){
  clockKnob.active = false;
  for(Sequencer seq : sequencers){
    seq.sidesKnob.active = false;
    seq.rotateKnob.active = false;
    seq.clkDivideKnob.active = false;
    seq.resetButton.wasPressed = false;
  }
}

// ---------------- OSC ----------------
void CV1In(float voltage){ assignCV(0,voltage); }
void CV2In(float voltage){ assignCV(1,voltage); }
void CV4In(float voltage){ assignCV(3,voltage); }
void CV5In(float voltage){ assignCV(4,voltage); }
void CV6In(float voltage){ assignCV(5,voltage); }
void CV7In(float voltage){ assignCV(6,voltage); }
void CV8In(float voltage){ assignCV(7,voltage); }

void assignCV(int index,float voltage){ CV[index]=voltage; }
