/*
* This sketch is meant to work with the Arduino
* 'sketch_4_proximity_test'.
*/

// serial stuff
import processing.serial.*;
Serial s_port;
boolean bSerialListen = false;
boolean touched = false;
int mprAddr = -1;
int padAddr = -1;
int datacount = -1;

PFont font;

color base  = color(0, 168, 255);
color filt  = color(240, 0, 0);
color touch = color(255, 0, 0);
color lines = color(220, 220, 220, 120);
color bckgr = color(30, 30, 30);

int NGRAPHS = 1;
Graph graphs[];


// SETUP ////////////////////////////////////////////////////////////////////////////
void setup()
{
  size(1000, 512);
  //fullScreen(2);
  //frameRate(30);
  smooth();
  
  float h = height / NGRAPHS;
  float w = width;

  // initialize the graphs
  graphs = new Graph[NGRAPHS];
  for(int i=0; i<NGRAPHS; i++)
  {
    graphs[i] = new Graph(0, h*i, w, h);
  }

  // serial stuff
  println(Serial.list());
  s_port = new Serial(this, Serial.list()[0], 115200);
  s_port.buffer( 2 );

  // graphics stuff
  font = loadFont("Monospaced-32.vlw");
  textFont(font, 24);
}

// DRAW /////////////////////////////////////////////////////////////////////////////
void draw()
{
  background(bckgr);

  if( bSerialListen )
  {
    for(int i=0; i<NGRAPHS;i++)
    {
      graphs[i].display();
    }
  }
  draw_other_info();
}

// SERIAL EVENT /////////////////////////////////////////////////////////////////////
// We are reaading pairs of 'ids' and 'values'
// id is always between 128 and 255.
void serialEvent(Serial s)
{
  int b = s.read();

  if(b > 127)
  {
    // we are reading a 'status' byte
    touched = ((b & 0x01) == 1);
    padAddr = (b>>1) & 0x0F;
    mprAddr = (b>>5) & 0x03; // after a 5 bit shift to the right, discard 6 MSB
    graphs[ mprAddr*12 + padAddr ].setTouch(touched);
    //print("mpr: " + mprAddr + "; pad: " + padAddr + "; touch: "+touched+"; ");
		datacount = 0;
  }
  else
  {
    // We are reading one of the two 'data' bytes.
    // Keep in mind that these raw values ('baseline' and 'filtered')
    // is trasmitted in 7bit (0-127); so they must be shifted left 
    // by 3 bit in order to scale them between 0 and 1023.
    if( datacount == 0)
    {
      // the byte contains the 'baseline' value
      graphs[ mprAddr*12 + padAddr ].setBase(b*8);
      //print("base: " + b + "; ");
      datacount = 1;
    }
    else
    {
      // the the byte contains the 'filtered' value
      graphs[ mprAddr*12 + padAddr ].setFilt(b*8);
      graphs[ mprAddr*12 + padAddr ].update();
      //println("filt: " + b + ".");
      datacount = 0; // reset datacount
    }
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
    for(int i=0; i<NGRAPHS; i++)
    {
      graphs[i].reset();
    }
  }
}

// CUSTOM ///////////////////////////////////////////////////////////////////////////
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
