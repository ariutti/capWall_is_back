class MPR121 
{
  // communication stuff
  int[] base;
  int[] filt;
  boolean[] touched;
  
  // graphics stuff
  PVector pos;
  float w, h;
  float space1 = 5;
  float space2 = 2;
  float d;
  
  // CONSTRUCTOR ///////////////////////////////////////////////
  MPR121(float _w, float _h, float _x, float _y)
  {
    pos = new PVector(_x, _y);
    w = _w;
    h = _h;
    d = (w - (11*space2) - (2*space1) ) / 12 ;
    
    base = new int[12];
    filt = new int[12];
    touched = new boolean[12];
    for(int i=0; i<12; i++) 
    {
      base[i] = 0;
      filt[i] = 0;
      touched[i] = false;
    }
  }
  
  // UPDATE ////////////////////////////////////////////////////
  void update()
  {
  }
  
  // DISPLAY ///////////////////////////////////////////////////
  void display()
  {
    pushStyle();
    pushMatrix();
    rectMode(CORNERS);
    fill(200);
    rect(pos.x, pos.y, pos.x+w, pos.y+h);
    for(int i=0; i<12; i++) 
    {
      if( touched[i] )
        fill(255, 0, 0);
      else
        noFill();
      stroke(255, 0, 0);
      ellipse( pos.x+space1+d*0.5+(d+space2)*i, pos.y+h*0.5, d, d);
    }
    popMatrix();
    popStyle();
  }
  
  void setBase(int padIdx, int _b)
  {
    if(padIdx<0 || padIdx > 11)
    {
      println("Error: invalid idx");
      return;
    }
    base[padIdx] = _b;
  }
  
  void setFilt(int padIdx, int _f)
  {
    if(padIdx<0 || padIdx > 11)
    {
      println("Error: invalid idx");
      return;
    }
    filt[padIdx] = _f;
  }
  
  void setTouch(int padIdx, boolean _t)
  {
    if(padIdx<0 || padIdx > 11)
    {
      println("Error: invalid idx");
      return;
    }
    touched[padIdx] = _t;
  }
}