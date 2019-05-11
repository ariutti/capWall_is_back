void setup() {
  Serial.begin(9600);
  Serial.println("Starting up!");
  pinMode(13, OUTPUT);

  for(int i=0; i<3; i++) {
    digitalWrite(13, HIGH);
    delay(1000);
    digitalWrite(13, LOW);
    delay(1000);
  }

}

void loop() {
  delay(10);
}
