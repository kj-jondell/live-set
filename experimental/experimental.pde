import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress netAddr;

int cols, rows;
int scale = 15;
int w = width;
int h = height;
float flying = 0;
float terrainHeight;
float[][] terrain;
color c1, c2;

void setup() {
  fullScreen(P3D);
  oscP5 = new OscP5(this, 7771);
  netAddr = new NetAddress("192.168.2.2", 7771);
  noCursor();
  stroke(255);
  noFill();
  cols = width / scale;
  rows = height / scale;
  terrain = new float[cols][rows];
  c1 = color(0, 255);
  c2 = color(0, 0);
}

void oscEvent(OscMessage msg){
  if(msg.checkAddrPattern("/terrainHeight")){
    try{
      t_height = msg.get(0).intValue();
    }catch(Exception e){
      println(msg.get(0));
      println(e); 
    }
  }
  if(msg.checkAddrPattern("/flySpeed")){
    try{
      flySpeed = msg.get(0).floatValue()/100;
    }catch(Exception e){
      println(msg.get(0));
      println(e); 
    }
  }

}

float flySpeed = 0;
int t_height = 0;
void draw() {
  background(0);
  flying -= flySpeed;
  float yOffset = flying;
  for (int y=0; y < rows; y++) {
    float xOffset = 0;
    for (int x=0; x < cols; x++) {
      terrainHeight = t_height;
      terrain[x][y] = map(noise(xOffset, yOffset), 0, 1, -terrainHeight, terrainHeight);
      xOffset += 0.1;
    } 
    yOffset += 0.1;
  }
  
  //translate(width/2, height/2);
  rotateX(PI/4);
  //translate(-w, -h);
  for (int y=0; y < rows-1; y++) {
    beginShape(TRIANGLE_STRIP);
    for (int x=0; x < cols; x++) {
      stroke(map(terrain[x][y], 0, 100, 150, 255), 125, 255, map(y, 0, rows, 0, 255));
      vertex(x*scale, y*scale, terrain[x][y]);
      vertex(x*scale, (y+1)*scale, terrain[x][y+1]);
    }
    endShape();
  }
}

