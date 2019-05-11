// The Nature of Code
// Daniel Shiffman
// http://natureofcode.com

// One vehicle "arrives"
// See: http://www.red3d.com/cwr/

Vehicle v;

void setup() {
  size(640, 240);
  //v = new Vehicle(width/2, height/2);
  v = new Vehicle(width/2);
}

void draw() {
  background(255);


  // Draw an ellipse at the mouse position
  fill(200);
  noStroke();
  ellipse(mouseX, height/2, 48, 48);

  // Call the appropriate steering behaviors for our agents
  
  v.update();
  v.display();
}

void mousePressed()
{
  v.arrive(mouseX);
}
