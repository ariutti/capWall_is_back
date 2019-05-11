#define BUTTON0 2
#define BUTTON1 3
#define BOARDLED 13

// optocoupler outputs
int opto[] = {2,3,4,5};

void setup() 
{
  Serial.begin(9600);
  
  for(int i=0; i<4; i++) {
    pinMode(opto[i], OUTPUT);
    digitalWrite(opto[i], LOW);
  }
}

void loop()
{
  for(int i=0; i<4; i++) {
    digitalWrite(opto[i], HIGH);
    delay(250);
    digitalWrite(opto[i], LOW);
    delay(5000);
  }
}
