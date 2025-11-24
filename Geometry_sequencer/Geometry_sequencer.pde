import oscP5.*;
import netP5.*;

OscP5 OSC;
float[] CV = new float[8];

final int MAX_SIDES = 32;

// --- sequencer center ---
float seqCenterX, seqCenterY;

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

VertexDot[] dots = new VertexDot[MAX_SIDES];

int currentStep = -1;
float clockTimer = 0;
float clockInterval = 0.5;

// --- Knob class ---
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

    // Draw text below knob for all
    text(label, x, y + radius + 15);

    String valStr = "";
    if(label.equals("Clock Speed")){
      float minInterval = 0.025;
      float maxInterval = 1.0;
      float interval = lerp(maxInterval, minInterval, value);
      valStr = int(interval*1000) + " ms";
    } else if(label.equals("Length 1")){
      int sides = int(map(value, 0, 1, 3, MAX_SIDES));
      valStr = sides + "";
    } else if(label.equals("Rotate 1")){
      int rot = int(map(value, 0, 1, 0, MAX_SIDES-1));
      valStr = rot + "";
    } else if(label.equals("Clk Divide 1")){
      int div = int(map(value,0,1,1,16));
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

// --- Four virtual knobs ---
Knob clockKnob, sidesKnob, rotateKnob, clkDivideKnob;

void setupKnobs(){
  float knobY = height - 80;  // all knobs aligned
  float spacing = 80;
  float centerX = seqCenterX;

  clkDivideKnob = new Knob(centerX - spacing, knobY, 20, "Clk Divide 1", 0.0);
  sidesKnob = new Knob(centerX, knobY, 20, "Length 1", 0.0);
  rotateKnob = new Knob(centerX + spacing, knobY, 20, "Rotate 1", 0.0);

  float margin = 60;
  clockKnob = new Knob(width - margin, knobY, 20, "Clock Speed", 0.2);
}

void setup() {
  size(960, 400);
  smooth();
  for(int i=0;i<MAX_SIDES;i++) dots[i] = new VertexDot();

  OSC = new OscP5(this,7000);
  for(int i=0;i<8;i++) OSC.plug(this,"CV"+(i+1)+"In","/ch/"+(i+1));

  seqCenterX = width * 0.15;
  seqCenterY = height * 0.4;
  setupKnobs();
}

void draw() {
  background(30);

  int sides = constrain(round(map(sidesKnob.value,0.0,1.0,3,MAX_SIDES)),3,MAX_SIDES);
  int rotIndex = floor(rotateKnob.value * (sides - 1));
  int clkDivide = int(map(clkDivideKnob.value, 0, 1, 1, 16));

  // Dynamic clock interval
  float minInterval = 0.025;
  float maxInterval = 1.0;
  clockInterval = lerp(maxInterval, minInterval, clockKnob.value) * clkDivide;

  clockTimer += 1.0/frameRate;
  if(clockTimer >= clockInterval){
    clockTimer = 0;
    if(currentStep != -1) dots[currentStep].resetColor();
    currentStep = (currentStep + 1) % sides;
  }

  translate(seqCenterX, seqCenterY);
  float radius = min(width,height)*0.25;

  float[] vx = new float[sides];
  float[] vy = new float[sides];
  float angleStep = TWO_PI / sides;

  for(int i=0; i<sides; i++){
    float angle = i * angleStep - HALF_PI;
    vx[i] = cos(angle) * radius;
    vy[i] = sin(angle) * radius;
    dots[i].x = vx[i]; dots[i].y = vy[i];
  }

  for(int i=0; i<sides; i++){
    int patternIndex = (i - rotIndex + sides) % sides;
    color dotBase = dots[patternIndex].baseCol;

    if(i == currentStep){
      if(dotBase == color(255,255,0)) dots[i].targetCol = color(0,255,0);
      else dots[i].targetCol = color(255,0,0);
    } else {
      dots[i].targetCol = dotBase;
    }
    dots[i].updateColor();
  }

  stroke(255); strokeWeight(2); noFill();
  beginShape();
  for(int i=0;i<sides;i++) vertex(vx[i],vy[i]);
  endShape(CLOSE);

  stroke(255); strokeWeight(2);
  float lineLength = radius * 0.2;
  line(0, -radius - 5, 0, -radius - 5 - lineLength);

  float dotSize = radius*0.15;
  for(int i=0;i<sides;i++) dots[i].display(dotSize);

  resetMatrix();

  clkDivideKnob.display();
  clockKnob.display();
  sidesKnob.display();
  rotateKnob.display();
}

void mousePressed(){
  if(clockKnob.hit(mouseX, mouseY)) clockKnob.active = true;
  if(sidesKnob.hit(mouseX, mouseY)) sidesKnob.active = true;
  if(rotateKnob.hit(mouseX, mouseY)) rotateKnob.active = true;
  if(clkDivideKnob.hit(mouseX, mouseY)) clkDivideKnob.active = true;

  float mx = mouseX - seqCenterX;
  float my = mouseY - seqCenterY;
  float radius = min(width,height)*0.25;
  float dotSize = radius*0.15;

  int sides = constrain(round(map(sidesKnob.value,0.0,1.0,3,MAX_SIDES)),3,MAX_SIDES);
  int rotIndex = floor(rotateKnob.value * (sides - 1));

  for(int i=0; i<sides; i++){
    int patternIndex = (i - rotIndex + sides) % sides;
    if(dots[i].isHit(mx,my,dotSize)) dots[patternIndex].toggle();
  }
}

void mouseDragged(){
  float dy = mouseY - pmouseY;
  if(clockKnob.active) clockKnob.drag(dy);
  if(sidesKnob.active) sidesKnob.drag(dy);
  if(rotateKnob.active) rotateKnob.drag(dy);
  if(clkDivideKnob.active) clkDivideKnob.drag(dy);
}

void mouseReleased(){
  clockKnob.active = false;
  sidesKnob.active = false;
  rotateKnob.active = false;
  clkDivideKnob.active = false;
}

// OSC functions
void CV1In(float voltage){ assignCV(0,voltage); }
void CV2In(float voltage){ assignCV(1,voltage); }
void CV4In(float voltage){ assignCV(3,voltage); }
void CV5In(float voltage){ assignCV(4,voltage); }
void CV6In(float voltage){ assignCV(5,voltage); }
void CV7In(float voltage){ assignCV(6,voltage); }
void CV8In(float voltage){ assignCV(7,voltage); }

void assignCV(int index,float voltage){ CV[index]=voltage; }
