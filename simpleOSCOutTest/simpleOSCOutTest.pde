import oscP5.*;
import netP5.*;

// OSC
OscP5 OSC;
NetAddress remote;
float[] CV = new float[8];

// Ball variables
float ballX, ballY;
float ballVX, ballVY;
float ballRadius = 20;

// CV3 gate timing
float gateEndTime = 0;
final float GATE_DURATION = 0.01; // 10 ms

void setup() {
  size(960, 400);

  // Ask user for IP
  String ip = promptForIP();   // e.g., "192.168.1.10" or leave blank for localhost
  if (ip.equals("")) ip = "127.0.0.1";

  // OSC setup
  OSC = new OscP5(this, 7000);           // local port
  remote = new NetAddress(ip, 7001);     // target port

  // Initialize CV values
  for (int i = 0; i < 8; i++) CV[i] = 0;

  // Initialize ball
  ballX = width/2;
  ballY = height/2;
  ballVX = random(150, 300) / 60.0; // px per frame
  ballVY = random(150, 300) / 60.0;
}

void draw() {
  background(30);

  float t = 1.0/frameRate;

  // Move ball
  ballX += ballVX;
  ballY += ballVY;

  boolean hitWall = false;

  // Check collisions
  if (ballX < ballRadius) { ballX = ballRadius; ballVX *= -1; hitWall = true; }
  if (ballX > width - ballRadius) { ballX = width - ballRadius; ballVX *= -1; hitWall = true; }
  if (ballY < ballRadius) { ballY = ballRadius; ballVY *= -1; hitWall = true; }
  if (ballY > height - ballRadius) { ballY = height - ballRadius; ballVY *= -1; hitWall = true; }

  // Draw ball
  fill(255, 200, 0);
  noStroke();
  ellipse(ballX, ballY, ballRadius*2, ballRadius*2);

  // CV output
  CV1Out();
  CV2Out();

  // CV3 gate on wall hit
  if (hitWall) gateEndTime = millis()/1000.0 + GATE_DURATION;
  CV3Out();

  // Reset other CVs to 0
  for (int i = 3; i < 8; i++) assignCV(i, 0);
}

// CV output functions
void CV1Out() {
  // Map X to -5V to +5V
  float cv = map(ballX, 0, width, -5, 5);
  assignCV(0, cv);
}

void CV2Out() {
  // Map Y to -5V to +5V
  float cv = map(ballY, 0, height, -5, 5);
  assignCV(1, cv);
}

void CV3Out() {
  float t = millis()/1000.0;
  if (t < gateEndTime) assignCV(2, 5.0);
  else assignCV(2, 0.0);
}

// Assign CV, print, and send OSC
void assignCV(int index, float voltage) {
  CV[index] = voltage;
  println("CV" + (index+1) + " Out: " + voltage);

  OscMessage msg = new OscMessage("/ch/" + (index+1));
  msg.add(voltage);
  OSC.send(msg, remote);
}

// Helper function to prompt for IP
String promptForIP() {
  return javax.swing.JOptionPane.showInputDialog("Enter target IP (leave blank for localhost):");
}
