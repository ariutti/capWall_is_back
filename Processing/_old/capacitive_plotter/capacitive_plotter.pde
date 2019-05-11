import processing.serial.*;
Serial s_port;
boolean bSerialListen = false;

final int ADDR_BASE0 = 20;
final int ADDR_FILT0 = 21;
final int ADDR_TOUCH0 = 22;
final int ADDR_BASE1 = 23;
final int ADDR_FILT1 = 24;
final int ADDR_TOUCH1 = 25;

int N = 100;
int baseline0[];
int filtered0[];
int baseline1[];
int filtered1[];
int current;

int USL = 626; //156B
int LSL = 405; //101B
int TAR = 562; //140B

int vBase0 = -1;
int vFilt0 = -1;
int vDelta0= -1;
int vBase1 = -1;
int vFilt1 = -1;
int vDelta1= -1;

int bestDelta0 = 0;
int bestDelta1 = 0;

int W=15;
int hGraph;
int offset = 0;
PFont font;

color base  = color(0, 168, 255);
color filt  = color(240, 0, 0);
color touch = color(255, 0, 0);
color lines = color(220, 220, 220, 120);
color bckgr = color(30, 30, 30);

boolean bTouch0 = false;
boolean bTouch1 = false;

// SETUP ////////////////////////////////////////////////////////////////////////////
void setup()
{
  size(1000, 512);  
  W = width/N;
  hGraph = height / 2;
  frameRate(30);
  smooth();
  
  //println(Serial.list());
  s_port = new Serial(this, Serial.list()[0], 9600);
  s_port.buffer( 2 );
  
  baseline0 = new int [N];
  filtered0 = new int [N];
  baseline1 = new int [N];
  filtered1 = new int [N];
  
  for (int i = 0; i < N; i++)
  {
    baseline0[i]=0;
    filtered0[i]=0;
    baseline1[i]=0;
    filtered1[i]=0;
  }
  current = 0;
  
  USL = (int)map(USL, 0, 1023, hGraph, 0);
  LSL = (int)map(LSL, 0, 1023, hGraph, 0);
  TAR = (int)map(TAR, 0, 1023, hGraph, 0);
  
  font = loadFont("Monospaced-32.vlw");
  textFont(font, 14);
}

// DRAW /////////////////////////////////////////////////////////////////////////////
void draw()
{
  background(bckgr);
  
  if( bSerialListen) 
  {
    draw_graph(0);
    draw_graph(1);
  }
  
  draw_other_info();
}
   
void update() {
  //if ( id == 0 ) {
    vDelta0 = vBase0 - vFilt0;
    if( abs(vDelta0) > bestDelta0 ) 
      bestDelta0 = abs(vDelta0);
      
      // graph 0
    int v =  (int)map(vBase0, 0, 1023, hGraph, 0);
    baseline0[current]= v;
    v = (int)map(vFilt0, 0, 1023, hGraph, 0);
    filtered0[current]= v;
  
  //} else if( if == 1 ) {
    vDelta1 = vBase1 - vFilt1;
    if( abs(vDelta1) > bestDelta1 ) 
      bestDelta1 = abs(vDelta1);
      
    // graph 1
    v =  (int)map(vBase1, 0, 1023, hGraph, 0);
    baseline1[current]= v;
    v = (int)map(vFilt1, 0, 1023, hGraph, 0);
    filtered1[current]= v;
  //}
  
  current++;
  current = current%N;
}

// SERIAL EVENT /////////////////////////////////////////////////////////////////////
void serialEvent(Serial s)
{
  int addr = s.read() - 128;
  
  switch( addr ) {
    case ADDR_BASE0:
      //print("#" + id + ", ");
      vBase0 = s.read() * 8;
      //print(vBase0 + "; ");
      break;
    case ADDR_FILT0:
      //print("#" + id + ", ");
      vFilt0 = s.read() * 8; 
      //print(vFilt0 + "; ");
      break;
    case ADDR_TOUCH0:
      //print("#" + id + ", ");
      if( s.read() == 1)
        bTouch0 = true;
      else
        bTouch0 = false;
      //print("bTouch0 = " + bTouch0);
      break;
    case ADDR_BASE1:
      //print("#" + id + ", ");
      vBase1 = s.read() * 8;
      //print(vBase1 + "; ");
      break;
    case ADDR_FILT1:
      //print("#" + id + ", ");
      vFilt1 = s.read() * 8; 
      //print(vFilt1 + "; ");
      break;
    case ADDR_TOUCH1:
      //print("#" + id + ", ");
      if( s.read() == 1)
        bTouch1 = true;
      else
        bTouch1 = false;
      //print("bTouch1 = " + bTouch1);
      // we have already collected all the values we wanted
      // now is time to update the graph
      update(); 
    default:
      // if id is not between 7 and 12
      // throw away the value
      int v = s.read();
      break;
  }
}

// KEY PRESSED //////////////////////////////////////////////////////////////////////
void keyPressed()
{
  if (key == 'o' || key == 'O')
  {
    s_port.write('o');
    bSerialListen = true;
  }
  else if( key == 'c' || key == 'C')
  {
    s_port.write('c');
    bSerialListen = false;
  }
  else if (key == 'r' || key == 'R')
  {
    s_port.write('r');
    bestDelta0 = 0;
    bestDelta1 = 0;
  }
}

// CUSTOM ///////////////////////////////////////////////////////////////////////////
void draw_graph(int id)
{
  draw_deltas( id );
  draw_baseline( id );
  draw_filtered( id );
  draw_touches( id );
  draw_axes_and_texts( id );
}

void draw_touches( int id )
{
  int r = 30;
  pushStyle();
  stroke( touch );
  
  
  fill( touch );
  if( id == 0 && bTouch0 )
  {
    offset = 0;
    ellipse(width - r - 5, 45 + offset, r, r);
  }
  else if (id == 1  && bTouch1 ) 
  {
    offset = hGraph;
    ellipse(width - r - 5, 45 + offset, r, r);
  } 
  popStyle();  
}

void draw_deltas(int id)
{
  pushStyle();
  noStroke();
  fill( base, 120 );
  if( id == 0 )
  {
    offset = 0;
    for(int i = 0; i < N; i++)
    {
      int delta = baseline0[i] - filtered0[i];
      rect(i*W, filtered0[i] + offset, W, delta);
    }
  }
  else if ( id == 1 ) 
  {
    offset = hGraph;
    for(int i = 0; i < N; i++)
    {
      int delta = baseline1[i] - filtered1[i];
      rect(i*W, filtered1[i] + offset, W, delta);
    }
  }
  popStyle();
}


void draw_baseline(int id)
{
  pushStyle();
  stroke(base);
  strokeWeight(2);
  if( id == 0 )
  {
    offset = 0;
    for(int i = 0; i < N; i++)
      line(i*W, baseline0[i] + offset, (i+1)*W, baseline0[i] + offset);
  }
  else if ( id == 1 ) 
  {
    offset = hGraph;
    for(int i = 0; i < N; i++)
      line(i*W, baseline1[i] + offset, (i+1)*W, baseline1[i] + offset);
  }
  popStyle();
}

void draw_filtered(int id)
{
  pushStyle();
  stroke(filt);
  strokeWeight(2);
  fill(filt);
  if( id == 0)
  {
    offset = 0;
    for(int i = 0; i < N; i++)
      ellipse( (i*W)+(W/2), filtered0[i]+offset, 2, 2);
  }
  else if ( id == 1 )
  {
    offset = hGraph;
    for(int i = 0; i < N; i++)
      ellipse( (i*W)+(W/2), filtered1[i]+offset, 2, 2);
  }
  popStyle();
}

void draw_axes_and_texts(int id)
{
  pushStyle();
  stroke(lines);
  strokeWeight(1);
  
  if( id == 0)
  {
    offset = 0;
    line(0, USL+offset, width, USL+offset);
    line(0, LSL+offset, width, LSL+offset);
    line(0, TAR+offset, width, TAR+offset);
    
    textAlign(LEFT);
    text("USL", 10, USL+offset-2);
    text("LSL", 10, LSL+offset-2);
    text("TAR", 10, TAR+offset-2);
    
    text("Base: "+vBase0, 10, 20+offset);
    text("Filt: "+vFilt0, 10, 40+offset);
    text("Dlta: "+vDelta0, 10, 60+offset);
    text("best: "+bestDelta0, 10, 80+offset);
    
    textAlign(RIGHT);
    text("Graph 0", width, offset+20);
  }
  else if( id == 1 )
  {
    offset = hGraph;
    line(0, USL+offset, width, USL+offset);
    line(0, LSL+offset, width, LSL+offset);
    line(0, TAR+offset, width, TAR+offset);
    
    textAlign(LEFT);
    text("USL", 10, USL+offset-2);
    text("LSL", 10, LSL+offset-2);
    text("TAR", 10, TAR+offset-2);
    
    text("Base: "+vBase1, 10, 20+offset);
    text("Filt: "+vFilt1, 10, 40+offset);
    text("Dlta: "+vDelta1, 10, 60+offset);
    text("best: "+bestDelta1, 10, 80+offset);
    
    textAlign(RIGHT);
    text("Graph 1", width, offset+20);
  }
  popStyle();
}

void draw_other_info()
{
  pushStyle();
  textAlign(CENTER);
  if( bSerialListen )
    text("Serial: ON", width/2, 20);
  else
    text("Serial: OFF", width/2, 20);
  popStyle();
}
