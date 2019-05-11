/*
* This sketch is meant to work with the
* "capacitive_plotter_3" sketch for Processing.
*/

#include <Wire.h>
#include "Limulo_MPR121.h"


#define NMPR 1
#define NPADS 2
#define FIRST_MPR_ADDR 0x5A


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


boolean bToPlotter;
int filt;
int base;
byte b;
int delayTime = 50;

// A boolean utility variable to print via serial 
// only when something is changed
boolean bToVVVV = true;


/************************************************************************************
 * SETUP
 ***********************************************************************************/
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
      Serial.print("MPR121 ");
      Serial.print(i);
      Serial.println(" not found, check wiring?");
      
      while (1);
    }
    Serial.print("MPR121 ");
    Serial.print(i);
    Serial.println(" ready!");

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

  bToPlotter=false;
}

/************************************************************************************
 * LOOP
 ***********************************************************************************/
void loop()
{
  // TODO: Add here serial communication section in order
  // to discard the serial event callback function

  // cycle through all the MPR
  for(int i=0; i<NMPR; i++)
  {
    mpr[i].currtouched = mpr[i].cap.touched(); // Get the currently touched pads
    // cycle through all the electrodes
    for(int j=0; j<NPADS; j++)
    {
      if (( mpr[i].currtouched & _BV(j)) && !(mpr[i].lasttouched & _BV(j)) )
      {
        // pad 'i' has been touched
        //Serial.println("Pad 0:\ttouched!");
        mpr[i].bPadState[j] = true;

        if( bToVVVV ) printAllSensors(); // Send serial data to VVVV
        
      }
      if (!(mpr[i].currtouched & _BV(j)) && (mpr[i].lasttouched & _BV(j)) )
      {
        // pad 'i' has been released
        //Serial.println("Pad 0 :\treleased!");
        mpr[i].bPadState[j] = false;
        
        if( bToVVVV ) printAllSensors(); // Send serial data to VVVV
      }
      
    }
    // reset our state
    mpr[i].lasttouched = mpr[i].currtouched;

    /*
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
      for(int j=0; j<NPADS; j++)
      {
        filt = mpr[i].cap.filteredData(j);
        base = mpr[i].cap.baselineData(j);
        b = (1<<7) | (i<<5) | (j<<1) | mpr[i].bPadState[j];
        Serial.write(b); // send address & touched
        Serial.write(base / 8); // send base value
        Serial.write(filt / 8); // send filtered value
      }
    } // if(bToPlotter)
    */

  } //  for(int i=0; i<NMPR; i++)
  
  delay(delayTime); // put a delay so it isn't overwhelming
}


/************************************************************************************
 * SERIAL EVENT
 ***********************************************************************************/
void serialEvent()
{
  byte c = Serial.read();
  if (c == 'o')
    bToPlotter = true;
  else if (c == 'c')
    bToPlotter = false;
  else if (c == 'r')
  {
    // reset all the MPR
    for(int i=0; i<NMPR; i++)
      mpr[i].cap.reset();
  }
}


/************************************************************************************
 * PRINT ALL SENSORS
 ***********************************************************************************/
void printAllSensors()
{
  // cycle through all the mpr
  for(int i=0; i<NMPR; i++)
  {
    // cycle through all the electrodes
    for(int j=0; j<NPADS; j++)
    {
      int state = (mpr[i].currtouched & _BV(j)) >> j;
      Serial.print( state );
    }
  }
  Serial.println(";");
}
