import oscP5.*;
import netP5.*;

OscP5 OSC;
float[] CV = new float[8];

final int MAX_SIDES = 32;

class VertexDot {
  float x, y;
  color baseCol = color(255);   // white or yellow
  color targetCol = baseCol;    // target color for fade
  color col = baseCol;          // displayed color

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

  void setActiveStep() {
    targetCol = (baseCol == color(255,255,0)) ? color(0,255,0) : color(255,0,0);
  }

  void resetColor() {
    targetCol = baseCol;
  }

  void updateColor() {
    float lerpAmt = 0.25;
    float r = lerp(red(col), red(targetCol), lerpAmt);
    float g = lerp(green(col), green(targetCol), lerpAmt);
    float b = lerp(blue(col), blue(targetCol), lerpAmt);
    col = color(r,g,b);
  }

  boolean isHit(float mx, float my, float dotSize) {
    return dist(mx,my,x,y) < dotSize/2;
  }
}

VertexDot[] dots = new VertexDot[MAX_SIDES];

int currentStep = -1;
float clockTimer = 0;
float clockInterval = 0.5; // seconds per step

// --- Knob class ---
class Knob {
  float x, y, radius;
  boolean active = false;
  float value;   // 0..1 normalized
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
    stroke(255);
    strokeWeight(3);
    line(x, y, x + cos(angle)*radius*0.8, y + sin(angle)*radius*0.8);
    
    noStroke();
    fill(255);
    textAlign(CENTER, CENTER);
    text(label, x, y + radius + 15);
    
    String valStr = "";
    if(label.equals("Clock Speed")){
      float speed = 0.1 + value*4.9;
      int msValue = int(clockInterval / speed * 1000);
      valStr = msValue + " ms";
    } else if(label.equals("Length 1")){
      int sides = int(map(value, 0, 1, 3, MAX_SIDES));
      valStr = sides + "";
    } else if(label.equals("Rotate 1")){
      int rot = int(map(value, 0, 1, 0, MAX_SIDES-1));
      valStr = rot + "";
    }
    text(valStr, x, y + radius + 35);
  }
  
  boolean hit(float mx, float my){
    return dist(mx, my, x, y) < radius;
  }
  
  void drag(float dy){
    value += -dy * 0.002;
    value = constrain(value, 0, 1);
  }
}

// --- Three virtual knobs ---
Knob clockKnob, sidesKnob, rotateKnob;

void setupKnobs(){
  float startX = width - 300;
  float startY = height - 80;
  float spacing = 80;
  float r = 20;
  clockKnob = new Knob(startX, startY, r, "Clock Speed", 0.2);
  sidesKnob = new Knob(startX + spacing, startY, r, "Length 1", 0.0);
  rotateKnob = new Knob(startX + spacing*2, startY, r, "Rotate 1", 0.0);
}

void setup() {
  size(960, 400);
  smooth();
  for(int i=0;i<MAX_SIDES;i++) dots[i] = new VertexDot();

  OSC = new OscP5(this,7000);
  for(int i=0;i<8;i++) OSC.plug(this,"CV"+(i+1)+"In","/ch/"+(i+1));

  setupKnobs();
}

void draw() {
  background(30);

  int sides = constrain(round(map(sidesKnob.value,0.0,1.0,3,MAX_SIDES)),3,MAX_SIDES);
  int rotIndex = floor(rotateKnob.value * (sides - 1));
  float angleStep = TWO_PI / sides;
  float clockSpeed = 0.1 + clockKnob.value*4.9;

  // --- clock updates ---
  clockTimer += (1.0/frameRate) * clockSpeed;
  if(clockTimer >= clockInterval){
    clockTimer = 0;
    if(currentStep != -1) dots[currentStep].resetColor();
    currentStep = (currentStep + 1) % sides;
  }

  translate(width/2, height/2);
  float radius = min(width,height)*0.35;

  float[] vx = new float[sides];
  float[] vy = new float[sides];

  for(int i=0; i<sides; i++){
    float angle = i * angleStep - HALF_PI;
    vx[i] = cos(angle) * radius;
    vy[i] = sin(angle) * radius;
    dots[i].x = vx[i];
    dots[i].y = vy[i];
  }

  // --- update colors (rotation only affects display, not toggle state) ---
  for(int i=0; i<sides; i++){
    int patternIndex = (i - rotIndex + sides) % sides; // visual rotation
    color dotBase = dots[patternIndex].baseCol;

    if(i == currentStep){
      if(dotBase == color(255,255,0)) dots[i].targetCol = color(0,255,0);
      else dots[i].targetCol = color(255,0,0);
    } else {
      dots[i].targetCol = dotBase;
    }

    dots[i].updateColor();
  }

  // --- draw polygon ---
  stroke(255); strokeWeight(2); noFill();
  beginShape();
  for(int i=0;i<sides;i++) vertex(vx[i],vy[i]);
  endShape(CLOSE);

// --- draw single "noon" line above Step 0 ---
stroke(255); 
strokeWeight(2);

// Step 0 is always at the top (angle -HALF_PI)
float lineLength = radius * 0.2; // length of the line
line(0, -radius - 5, 0, -radius - 5 - lineLength); // vertical line above the top vertex

  // --- draw dots ---
  float dotSize = radius*0.15;
  for(int i=0;i<sides;i++) dots[i].display(dotSize);

  resetMatrix();

  // --- draw knobs ---
  clockKnob.display();
  sidesKnob.display();
  rotateKnob.display();
}

void mousePressed(){
  if(clockKnob.hit(mouseX, mouseY)) clockKnob.active = true;
  if(sidesKnob.hit(mouseX, mouseY)) sidesKnob.active = true;
  if(rotateKnob.hit(mouseX, mouseY)) rotateKnob.active = true;

  float mx = mouseX - width/2;
  float my = mouseY - height/2;
  float radius = min(width,height)*0.35;
  float dotSize = radius*0.15;

  int sides = constrain(round(map(sidesKnob.value,0.0,1.0,3,MAX_SIDES)),3,MAX_SIDES);
  int rotIndex = floor(rotateKnob.value * (sides - 1));

  for(int i=0; i<sides; i++){
    int patternIndex = (i - rotIndex + sides) % sides; // map visual to actual dot
    if(dots[i].isHit(mx,my,dotSize)) {
      dots[patternIndex].toggle();
    }
  }
}

void mouseDragged(){
  float dy = mouseY - pmouseY;
  if(clockKnob.active) clockKnob.drag(dy);
  if(sidesKnob.active) sidesKnob.drag(dy);
  if(rotateKnob.active) rotateKnob.drag(dy);
}

void mouseReleased(){
  clockKnob.active = false;
  sidesKnob.active = false;
  rotateKnob.active = false;
}

// OSC functions (optional)
void CV1In(float voltage){ assignCV(0,voltage); }
void CV2In(float voltage){ assignCV(1,voltage); }
void CV4In(float voltage){ assignCV(3,voltage); }
void CV5In(float voltage){ assignCV(4,voltage); }
void CV6In(float voltage){ assignCV(5,voltage); }
void CV7In(float voltage){ assignCV(6,voltage); }
void CV8In(float voltage){ assignCV(7,voltage); }

void assignCV(int index,float voltage){ CV[index]=voltage; }
