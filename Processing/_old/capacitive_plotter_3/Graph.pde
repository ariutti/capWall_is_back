/* 
* We must have a graph per pad
*/

class Graph 
{
  int N = 100;
  float W, hGraph;
  
  int baseline[];
  int filtered[];
  
  // raw value coming from serial communication
  int vBase = -1;
  int vFilt = -1;
  int vDelta= -1;
  int bestDelta = 0;

  int offset = 0;
  int current = 0;
  
  boolean bTouch = false;
  
  int USL = 806;
  int TL = 726;
  int LSL = 524;
  int mappedUSL, mappedTL, mappedLSL;
  
  PVector pos;

  // CONTRUCTOR ////////////////////////////////////////////////////////
  Graph(float _x, float _y, float _w, float _h)
  {
    pos = new PVector(_x, _y);
    W = _w/N;
    hGraph = _h / NGRAPHS;
    baseline= new int [N];
    filtered= new int [N];
    for (int i = 0; i < N; i++)
    {
      baseline[i]=0;
      filtered[i]=0;
    }
    mappedUSL = (int)map(USL, 0, 1023, hGraph, 0);
    mappedLSL = (int)map(LSL, 0, 1023, hGraph, 0);
    mappedTL = (int)map(TL, 0, 1023, hGraph, 0);
  }
  
  // called when we have received the complete triplet of data
  // from Arduino via the Serial communication.
  void update()
  {
    // find the best delta
    vDelta = vBase - vFilt;
    if( abs(vDelta) > bestDelta )
    {
      bestDelta = abs(vDelta);
    }

    // the graph
    int v =  (int)map(vBase, 0, 1023, hGraph, 0);
    baseline[current]= v;
    v = (int)map(vFilt, 0, 1023, hGraph, 0);
    filtered[current]= v;
    current++;
    current = current%N;  
  }
  
  void display()
  {
    pushMatrix();
    translate(pos.x, pos.y);
    draw_deltas();
    draw_baseline();
    draw_filtered();
    draw_touches();
    draw_axes_and_texts();
    popMatrix();
  }
   
  /*
  * to be called when a key pressed
  */
  void reset()
  {
    bestDelta = 0;
  }
  
  // called during serial communication
  void setTouch(boolean _b)
  {
    bTouch = _b;
  }
  
  void setBase(int _b)
  {
    vBase = _b;
  }
  
  void setFilt(int _b)
  {
    vFilt = _b;
  } 
  
  
  /* custom functions *****************************************************/
  
  void draw_touches()
  {
    int r = 30;
    pushStyle();
    stroke( touch );
  
    if( bTouch)
    {
      fill( touch );
    }
    else
    { 
      noFill();
    }
    
    offset = 0;
    ellipse(width - r - 5, 45 + offset, r, r);
    
    popStyle();
  }
  
  void draw_deltas()
  {
    pushStyle();
    noStroke();
    fill( base, 120 );
    
    offset = 0;
    for(int i = 0; i < N; i++)
    {
      int delta = baseline[i] - filtered[i];
      rect(i*W, filtered[i] + offset, W, delta);
    }
    popStyle();
  }
  
  
  void draw_baseline()
  {
    pushStyle();
    stroke(base);
    strokeWeight(2);
    
    offset = 0;
    for(int i = 0; i < N; i++)
    {
      line(i*W, baseline[i] + offset, (i+1)*W, baseline[i] + offset);
    }
    popStyle();
  }
  
  
  void draw_filtered()
  {
    pushStyle();
    stroke(filt);
    strokeWeight(2);
    fill(filt);

    offset = 0;
    for(int i = 0; i < N; i++)
    {
      ellipse( (i*W)+(W/2), filtered[i]+offset, 2, 2);
    }
    
    popStyle();
  }
  
  
  void draw_axes_and_texts()
  {
    pushStyle();
    stroke(lines);
    strokeWeight(1);
  
    offset = 0;
    line(0, mappedUSL+offset, width, mappedUSL+offset);
    line(0, mappedLSL+offset, width, mappedLSL+offset);
    line(0, mappedTL+offset, width, mappedTL+offset);

    textAlign(RIGHT);
    text("USL: " + USL, width-10, mappedUSL+offset-2);
    text("LSL:" + LSL, width-10, mappedLSL+offset-2);
    text("TL:" + TL, width-10, mappedTL+offset-2);

    textAlign(LEFT);
    text("Base: "+vBase, 10, 20+offset);
    text("Filt: "+vFilt, 10, 40+offset);
    text("Dlta: "+vDelta, 10, 60+offset);
    text("best: "+bestDelta, 10, 80+offset);

    //textAlign(RIGHT);
    //text("Graph 0", width, offset+20);
    popStyle();
  }
}
