import oscP5.*;
import netP5.*;

// ---------------- Global ----------------
OscP5 OSC;
NetAddress remote;

// Separate arrays for CV inputs and outputs
float[] CVin  = new float[8];
float[] CVout = new float[8];

// For CV trigger logic
final float PULSE_DURATION = 0.005;       // 5 ms pulse

final int MAX_SIDES = 32;

// --- main clock ---
Knob clockKnob;
Button resetAllButton;  // Reset all sequencers

// --- Sequencer array ---
Sequencer[] sequencers;

// ==================== VertexDot ====================
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

  void toggleColor() { 
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

// ==================== Knob ====================
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

// ==================== Button ====================
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
    fill(255);
    noStroke();
    ellipse(x, y, radius*2, radius*2);

    if(flashAlpha > 0){
      fill(255,0,0, flashAlpha);
      ellipse(x, y, radius*2, radius*2);
      flashAlpha -= 5;
      if(flashAlpha < 0) flashAlpha = 0;
    }

    fill(255);
    textAlign(CENTER, TOP);
    text(label, x, y + radius + 5);
  }

  boolean hit(float mx, float my){
    return dist(mx, my, x, y) < radius;
  }

  void trigger(){ 
    flashAlpha = 255;
  }
}

// ==================== Sequencer ====================
class Sequencer {
  float centerX, centerY;
  VertexDot[] dots;
  boolean[] stepActive;     
  int currentStep = -1;
  Knob sidesKnob, rotateKnob, clkDivideKnob;
  float nextStepTime = 0;   
  float pulseEndTime = 0;   
  Button resetButton;
  int seqIndex; 

  Sequencer(float centerX, float centerY, int seqIndex){
    this.centerX = centerX;
    this.centerY = centerY;
    this.seqIndex = seqIndex;
    dots = new VertexDot[MAX_SIDES];
    stepActive = new boolean[MAX_SIDES];
    for(int i=0;i<MAX_SIDES;i++){
      dots[i] = new VertexDot();
      stepActive[i] = false;
    }

    float knobY = height - 80; 
    float spacing = 80;

    clkDivideKnob = new Knob(centerX - spacing, knobY, 20, "Clk Divide", 0.0);
    sidesKnob     = new Knob(centerX, knobY, 20, "Length", 0.0);
    rotateKnob    = new Knob(centerX + spacing, knobY, 20, "Rotate", 0.0);

    resetButton = new Button(centerX, centerY, 20, "Reset");

    nextStepTime = millis()/1000.0; 
  }

  void update(float mainClockInterval){
    float t = millis()/1000.0; 
    int sides = constrain(round(map(sidesKnob.value,0,1,3,MAX_SIDES)),3,MAX_SIDES);
    int rotIndex = floor(rotateKnob.value*(sides-1));
    int clkDivide = max(1, int(map(clkDivideKnob.value,0,1,1,16)));

    float interval = mainClockInterval * clkDivide;

    if(t >= nextStepTime){
      currentStep = (currentStep + 1) % sides;
      nextStepTime += interval;

      int patternIndex = (currentStep - rotIndex + sides) % sides;
      if(stepActive[patternIndex]){
        assignCVOut(seqIndex, 5.0);
        pulseEndTime = t + PULSE_DURATION;
      }

      if(currentStep != -1) dots[currentStep].resetColor();
    }

    if(t >= pulseEndTime && pulseEndTime > 0){
      assignCVOut(seqIndex, 0.0);
      pulseEndTime = 0;
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
      color dotBase = stepActive[patternIndex] ? color(255,255,0) : color(255);
      if(i == currentStep){
        dots[i].targetCol = stepActive[patternIndex] ? color(0,255,0) : color(255,0,0);
      } else {
        dots[i].targetCol = dotBase;
      }
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
      if(dots[i].isHit(adjX,adjY,dotSize)){
        stepActive[patternIndex] = !stepActive[patternIndex]; 
        dots[patternIndex].toggleColor(); 
      }
    }

    if(resetButton.hit(mx,my) && !resetButton.wasPressed){
      resetButton.trigger();
      currentStep = -1;
      nextStepTime = millis()/1000.0;
    }
    resetButton.wasPressed = resetButton.hit(mx,my);
  }
}

// ==================== Setup ====================
void setup() {
  size(960, 400);
  String ip = promptForIP();
  if(ip.equals("")) ip = "127.0.0.1";

  smooth();
  OSC = new OscP5(this,7000);
  remote = new NetAddress(ip, 7001);

  for(int i=0;i<8;i++){
    OSC.plug(this,"CV"+(i+1)+"In","/ch/"+(i+1));
  }

  float marginX = width/6;
  sequencers = new Sequencer[3];
  sequencers[0] = new Sequencer(marginX, height*0.45, 0);
  sequencers[1] = new Sequencer(width/2, height*0.45, 1);
  sequencers[2] = new Sequencer(width-marginX, height*0.45, 2);

  for(Sequencer seq : sequencers){
    seq.sidesKnob.value = map(16,3,MAX_SIDES,0,1);
  }

  clockKnob = new Knob(width-50,50,20,"Clock Speed", map(0.1,1.0,0.025,0,1));
resetAllButton = new Button(clockKnob.x - 50, clockKnob.y, 20, "Reset All");
}

// ==================== Draw ====================
void draw() {
  background(30);

  float mainClockInterval = lerp(1.0,0.025,clockKnob.value);

  for(Sequencer seq : sequencers){
    seq.update(mainClockInterval);
  }

  clockKnob.display();
  resetAllButton.display();
}

// ==================== Mouse ====================
void mousePressed(){
  if(clockKnob.hit(mouseX, mouseY)) clockKnob.active = true;

  if(resetAllButton.hit(mouseX, mouseY) && !resetAllButton.wasPressed){
    resetAllButton.trigger();
    for(Sequencer seq : sequencers){
      seq.currentStep = -1;
      seq.nextStepTime = millis()/1000.0;
    }
  }
  resetAllButton.wasPressed = resetAllButton.hit(mouseX, mouseY);

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
  resetAllButton.wasPressed = false;
  for(Sequencer seq : sequencers){
    seq.sidesKnob.active = false;
    seq.rotateKnob.active = false;
    seq.clkDivideKnob.active = false;
    seq.resetButton.wasPressed = false;
  }
}

// ==================== CV Handling ====================
void CV1In(float voltage){ assignCVIn(0,voltage); }
void CV2In(float voltage){ assignCVIn(1,voltage); }
void CV3In(float voltage){ assignCVIn(2,voltage); }
void CV4In(float voltage){ assignCVIn(3,voltage); }
void CV5In(float voltage){ assignCVIn(4,voltage); }
void CV6In(float voltage){ assignCVIn(5,voltage); }
void CV7In(float voltage){ assignCVIn(6,voltage); }
void CV8In(float voltage){ assignCVIn(7,voltage); }

void assignCVIn(int index, float voltage){ CVin[index] = voltage; }
void assignCVOut(int index, float voltage){
  CVout[index] = voltage;
  OscMessage msg = new OscMessage("/ch/" + (index+1));
  msg.add(voltage);
  OSC.send(msg, remote);
}

// ==================== Utility ====================
String promptForIP() {
  return javax.swing.JOptionPane.showInputDialog("Enter target IP (leave blank for localhost):");
}
