/*
Given a number of consecutive array elements,
We are interested in finding a blob of consecutive ones.
Then we want to find the centroid index.

The 'getPadsCentroid' function scans the pads array and
returns the float index of the centroid in case there's one.
The function return -1 if there is no active pad.

TODO: the system is intrinsecly monophonic. This is exaclty
how the user experience is meant to work but, we have a problem.
What will happen if someone start touching the rightmost part 
of the padstrip and then the leftmost one?

The rightmost 'voice' will be immediately stolen from the leftmost one.
*/

final int NPADS = 12;
final int NLEDS = 46;
// indexes    0  1  2  3  4  5  6  7  8  9 10 11
int pads[] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

int accumulator;
int consecutives;
float centroidPads;
int centroidLed;

// SETUP /////////////////////////////////
void setup()
{
  size(200, 200);
  
  accumulator= 0;
  consecutives=0;
  centroidPads = 0.0;
  centroidLed = 0;
  
  printArray(pads);
  centroidPads = getPadsCentroid();
  println("consecutives = " + consecutives + ";");
  println("accumulator = " + accumulator + ";");
  println(centroidPads);
}

// DRAW //////////////////////////////////
void draw()
{
  // do nothing
}

// CUSTOM FUNCTIONS //////////////////////
float getPadsCentroid()
{
  for(int i=0; i<NPADS; i++)
  {
    println("index: " + i + ";");
    if(pads[i]==1)
    {
      accumulator += i;
      consecutives ++;
      continue;      
    }
    else
    {
      if((i-1)<0)
      {
        continue;
      }
      else if(pads[i-1] == 1)
      {
        break;
      }
    }
  }
  // when we arrive here we have eventually found a pad's blob
  // and so we can compute its centroid.
  if(consecutives==0)
  {
    println("consecutives =0");
    return -1;
  }
  else if(consecutives==1)
  {
    println("consecutives =1");
    return accumulator;
  }
  else
  {
    return (accumulator*1.0) / consecutives;
  }
}
