// The Nature of Code
// Daniel Shiffman
// http://natureofcode.com

// The "Vehicle" class

class Vehicle 
{
    
  float position;
  float velocity;
  float acceleration;
  
  float maxforce;    // Maximum steering force
  float maxspeed;    // Maximum speed
  
  float target;
  int DAMPING_DISTANCE = 100;

  //Vehicle(float x, float y) {
  Vehicle(float x) 
  {    
    acceleration = 0.0;
    velocity = 0.0;
    position = x;
    target = position;

    maxspeed = 10;
    maxforce = 0.5;
  }

  // Method to update position
  void update() 
  {     
    float desired = target - position;  // A float pointing from the position to the target
    float d = abs(desired);
    
    if( d == 0.0 )
    {
      // we are already there
      return;
    }
    // Scale with arbitrary damping within 100 pixels
    else if (d < DAMPING_DISTANCE) 
    {
      float m = map(d,0,DAMPING_DISTANCE,0,maxspeed);
      desired = (desired * m)/d;
    } 
    else
    {
      desired = (desired * maxspeed)/d;
    }

    // Steering = Desired minus Velocity
    float steer = desired - velocity;
    if(abs(steer) >= maxforce)
      steer = (steer*maxforce)/abs(steer); // Limit to maximum steering force
    
    // We could add mass here if we want A = F / M
    acceleration += steer;
    
    // Update velocity
    velocity +=acceleration;
    // Limit speed
    if(abs(velocity) >= maxspeed)
      velocity = (velocity*maxspeed)/abs(velocity);
    // Update position
    position += velocity;
    // Reset accelerationelertion to 0 each cycle
    acceleration = 0.0;
  }


  // A method that calculates a steering force towards a target
  // STEER = DESIRED MINUS VELOCITY
  void arrive(float _target) 
  {
    target = _target;
  }
  
  
  void display() 
  {
    // Draw a triangle rotated in the direction of velocity
    
    pushMatrix();
    
    fill(200, 0, 0, 120);
    noStroke();
    ellipse(target, height/2, DAMPING_DISTANCE, DAMPING_DISTANCE);
    
    strokeWeight(1);
    fill(200, 0, 0);
    stroke(0);
    ellipse(position, height/2, 10, 10);
    
    popMatrix();
  }
}
