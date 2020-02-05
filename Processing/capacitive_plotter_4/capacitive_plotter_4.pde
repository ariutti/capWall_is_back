/* 
* This is a sketch to plot raw data from Arduino.
* This data describe MPR (one ore more) capacitive pad sensors informations.
* In order to have a dedicated graph for each capacitive pad,
* even if pads are connected to different MPRs with different topology
* (i.e. first MPR has 2 pads, 2nd has only one, 3rd has 3 pads),
* you must describe precisely how the system is organized 
* (see NMPR, NPADS below - which are the exact same values you 
* find in your Arduino sketck).
* 
* How to use:
* 1. launch the sketch and press 'o' to open serial communication w/ Arduino;
*    It may not work at the beginning due to some error on the serial (don't know how to solve).
*    However it is only a temporary error. To solve, press 'o' again or restart the sketch.
* 2. Touch the pads to see the graphs moving and plotting data;
* 3. Press 'c' to close serial port;
* 4. Press 'r' to reset all graphs and MPRs.
*/

// put here the number of MPR you are using
final int NMPR = 4;
// put here the number of pad used by each MPR
final int NPADS[] = {1,1,1,1};
// number of graphs will be calculated according to NPADS
int NGRAPHS; 
Graph graphs[];


// serial stuff
import processing.serial.*;
Serial s_port;
boolean bSerialListen = false;
boolean touched = false;
int mprAddr = -1;
int padAddr = -1;
int datacount = -1;
int gidx = -1;

PFont font;

color base  = color(0, 168, 255);
color filt  = color(240, 0, 0);
color touch = color(255, 0, 0);
color lines = color(220, 220, 220, 120);
color bckgr = color(30, 30, 30);

// SETUP ////////////////////////////////////////////////////////////////////////////
void setup()
{
  //size(1200, 800);
  fullScreen(2);
  smooth();
  
  NGRAPHS = 0;
  for(int i=0; i<NMPR; i++) 
    NGRAPHS += NPADS[i];
  println(NGRAPHS);
  
  float h = height / NGRAPHS;
  float w = width;

  // initialize the graphs
  graphs = new Graph[NGRAPHS];
  for(int i=0; i<NGRAPHS; i++) {
    graphs[i] = new Graph(0, h*i, w, h);
  }

  // serial stuff
  println(Serial.list());
  s_port = new Serial(this, Serial.list()[0], 9600);
  s_port.buffer( 2 );

  // graphics stuff
  font = loadFont("Monospaced-32.vlw");
  textFont(font, 18);
}

// DRAW /////////////////////////////////////////////////////////////////////////////
void draw()
{
  background(bckgr);

  if( bSerialListen )
  {
    for(int i=0; i<NGRAPHS;i++) {
      graphs[i].display();
    }
  }
  draw_other_info();
}

// SERIAL EVENT /////////////////////////////////////////////////////////////////////
// We are reading pairs of 'ids' and 'values'
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
    gidx = getGraphIndex(mprAddr, padAddr);//graph index
    //graphs[ mprAddr*12 + padAddr ].setTouch(touched);
    graphs[ gidx ].setTouch(touched);
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
      //graphs[ mprAddr*12 + padAddr ].setBase(b*8);
      graphs[ gidx ].setBase(b*8);
      //print("base: " + b + "; ");
      datacount = 1;
    }
    else
    {
      // the the byte contains the 'filtered' value
      //graphs[ mprAddr*12 + padAddr ].setFilt(b*8);
      //graphs[ mprAddr*12 + padAddr ].update();
      
      graphs[ gidx ].setFilt(b*8);
      graphs[ gidx ].update();
      
      //println("filt: " + b + ".");
      datacount = 0; // reset datacount
    }
  }
}

// An utility function wich will be used to match 
// each pad on its dedicated graph 
int getGraphIndex(int _mprAddr, int _padAddr)
{
  int graphIdx = 0;
  for(int i=0; i<_mprAddr; i++) {
    graphIdx += NPADS[i];
  }
  graphIdx += _padAddr;
  return graphIdx;
}

// KEY PRESSED //////////////////////////////////////////////////////////////////////
void keyPressed()
{
  // press '1' to zoom in 
  if( key == '1' ) {
    for(int i=0; i<graphs.length; i++) {
      graphs[i].zoomIn();
    }
  } 
  // press '2' to zoom out 
  else if( key == '2' ) {
    for(int i=0; i<graphs.length; i++) {
      graphs[i].zoomOut();
    }
  } 
  // press '0' to reset the zoom to its default value
  else if( key == '0') {
    for(int i=0; i<graphs.length; i++) {
      graphs[i].zoomReset();
    }
  } 
  // press 'o' to open serial communication w/ Arduino
  else if (key == 'o' || key == 'O') {
    s_port.write('o');
    bSerialListen = true;
  }
  // press 'c' to close serial communication w/ Arduino
  else if( key == 'c' || key == 'C') {
    s_port.write('c');
    bSerialListen = false;
  }
  // press 'r' to reset all graphs and also send an 'r' 
  // to Arduino in order for it to reset each MPR boards
  else if (key == 'r' || key == 'R') {
    s_port.write('r');
    for(int i=0; i<NGRAPHS; i++) {
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
  
// ARDUINO CODE ///////////////////////////////////////////////////////////////////
/*
#include <Wire.h>
#include "Limulo_MPR121.h"

#define FIRST_MPR_ADDR 0x5A
const int NMPR = 4;
const int NPADS[] = {1, 1, 3, 2};



struct mpr121
{
  Limulo_MPR121 cap;
  uint8_t addr;
  // Save an history of the pads that have been touched/released
  uint16_t lasttouched = 0;
  uint16_t currtouched = 0;
  boolean bPadState[12];
};


// an array of mpr121! You can have up to 4 on the same i2c bus
mpr121 mpr[NMPR];

// A boolean utility variable to print via serial 
// only when something is changed
// If data are going to the plotter they will be not sent 
// in the form of 0000100;
// and viceversa.

// some booolean variables
boolean bDebug = false;
boolean bToV4 = false;
// the Serial plotter boolean will be set via Processing
boolean bToPlotter;

int filt;
int base;
byte b;
int delayTime = 10;

// SETUP
void setup()
{
  // open the I2C communication
  Serial.begin(9600, SERIAL_8N1);

  // cycle through all the MPR
  for(int i=0; i<NMPR; i++)
  {
    mpr[i].cap = Limulo_MPR121();
    // mpr address can be one of these: 0x5A, 0x5B, 0x5C o 0x5D
    mpr[i].addr = FIRST_MPR_ADDR + i;

    // Look for the MPR121 chip on the I2C bus
    if ( !mpr[i].cap.begin( mpr[i].addr ) )
    {
      if(bDebug) Serial.print("MPR121 ");
      if(bDebug) Serial.print(i);
      if(bDebug) Serial.println(" not found, check wiring?");
      
      while (1);
    }
    if(bDebug) Serial.print("MPR121 ");
    if(bDebug) Serial.print(i);
    if(bDebug) Serial.println(" ready!");

    // initialize the array of booleans
    for(int j=0; j<12; j++)
    {
      mpr[i].bPadState[j] = false;
    }

    mpr[i].cap.setUSL(201);
    mpr[i].cap.setTL(180);
    mpr[i].cap.setLSL(130);

    // possibly initialize the mpr with some initial settings
    // mhd, nhd, ncl, fdl
    mpr[i].cap.setFalling(1, 1, 2, 1);
    mpr[i].cap.setRising( 1, 8, 1, 0);
    mpr[i].cap.setTouched( 0, 0, 0);
    
    mpr[i].cap.setThresholds( 24, 5 );
    //mpr.setDebounces(1, 1);
  }
  bToPlotter = false;
}

// LOOP
void loop()
{
  // TODO: Add here serial communication section in order
  // to discard the serial event callback function

  // cycle through all the MPR
  for(int i=0; i<NMPR; i++)
  {
    mpr[i].currtouched = mpr[i].cap.touched(); // Get the currently touched pads
    // cycle through all the electrodes
    for(int j=0; j<NPADS[i]; j++)
    {
      if (( mpr[i].currtouched & _BV(j)) && !(mpr[i].lasttouched & _BV(j)) )
      {
        // pad 'i' has been touched
        //Serial.println("Pad 0:\ttouched!");
        mpr[i].bPadState[j] = true;

        if( bToV4 ) printAllSensors(); // Send serial data to VVVV
        
      }
      if (!(mpr[i].currtouched & _BV(j)) && (mpr[i].lasttouched & _BV(j)) )
      {
        // pad 'i' has been released
        //Serial.println("Pad 0 :\treleased!");
        mpr[i].bPadState[j] = false;
        
        if( bToV4 ) printAllSensors(); // Send serial data to VVVV
      }
      
    }
    // reset our state
    mpr[i].lasttouched = mpr[i].currtouched;

    
    // Send Serial data ////////////////////////////////////////////////////////////
    if(bToPlotter)
    {
      // Send data via serial:
      // 1. First send a byte containing the address of the mpr + the address of the pad +
      //    the 'touched' status of the pad; This byte has a value greater than 127 by convention;
      // 2. Then send two more bytes for 'baseline' and 'filtered' respectively. 
      //    Because these values are 10bit values and we must send them
      //    inside a 7bit packet, we must made a 3 times bit shift to the right (/8).
      //    This way we will loose some precision but this is not important.
      //    This two other bytes have values lesser than 127 by convention.

      // cycle all the electrodes
      for(int j=0; j<NPADS[i]; j++)
      {
        filt = mpr[i].cap.filteredData(j);
        base = mpr[i].cap.baselineData(j);
        b = (1<<7) | (i<<5) | (j<<1) | mpr[i].bPadState[j];
        Serial.write(b); // send address & touched
        Serial.write(base / 8); // send base value
        Serial.write(filt / 8); // send filtered value
      }
    } // if(bToPlotter)
    

  } //  for(int i=0; i<NMPR; i++)
  
  delay(delayTime); // put a delay so it isn't overwhelming
}


// SERIAL EVENT
void serialEvent()
{
  byte c = Serial.read();
  // Processing can ask Arduino to send some raw
  // data in order to get a plotted version of them
  if (c == 'o') {
    bToPlotter = true;
  }
  else if (c == 'c') {
    bToPlotter = false;
  }
  // V4 can open or close the serial communication with Arduino
  else if( 'a' ) {
    bToPlotter = false;
    bToV4 = true;
  }
  else if( 'b' ) {
    bToV4 = false;
  }
  else if (c == 'r')
  {
    // reset all the MPR
    for(int i=0; i<NMPR; i++)
      mpr[i].cap.reset();
  }
}

// PRINT ALL SENSORS
void printAllSensors()
{
  // cycle through all the mpr
  for(int i=0; i<NMPR; i++)
  {
    // cycle through all the electrodes
    for(int j=0; j<NPADS[i]; j++)
    {
      int state = (mpr[i].currtouched & _BV(j)) >> j;
      Serial.print( state );
    }
  }
  Serial.println(";");
}
*/
