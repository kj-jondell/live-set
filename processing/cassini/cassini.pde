PShape s, moon;
PImage img,moonground;

void setup() {
  fullScreen(P3D);
  noCursor();
  pixelDensity(2);

  noStroke();
  smooth();

  s = createShape(SPHERE,30);
  moon = createShape(SPHERE,8);
  s.scale(5);
  moon.scale(5);

  img = loadImage("earth2.jpg");
  s.setTexture(img);
  moon.setTexture(loadImage("moon.jpg"));
  moon.translate(0,0,400);

  perspective();//TODO:remove?
  background(0);
}

void draw() {
  clear();

  moon.rotate(0.001,0,1,0);
  s.rotate(0.001,0,1,0);

  directionalLight(255,255,255, -1,0.25,0);
  ambientLight(30,30,30);
  shape(moon,width/2,height/2);
  shape(s,width/2,height/2);

}
