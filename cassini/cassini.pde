PShape s, moon;
PImage img,moonground;

void setup() {
  //size(600,400, P3D);
  fullScreen(P3D);
  noCursor();
  pixelDensity(2);
  // The file "bot.obj" must be in the data folder
  // of the current sketch to load successfully
  //s = loadShape("untitled.obj");
  noStroke();
  smooth();

  s = createShape(SPHERE,30);
  moon = createShape(SPHERE,8);
  s.scale(5);
  moon.scale(5);
  //img = loadImage("jup.jpg");
  img = loadImage("earth2.jpg");
  s.setTexture(img);
  moon.setTexture(loadImage("moon.jpg"));
  moon.translate(0,0,400);

 // moonground = loadImage("earthrise.jpg");
  perspective();
  background(0);
}

void draw() {
  clear();

  moon.rotate(0.001,0,1,0);
  s.rotate(0.001,0,1,0);
  //s.translate(0,0,0);
//  image(moonground,0,height-400,width,400);

  directionalLight(255,255,255, -1,0.25,0);
  //spotLight(51, 102, 126, 80, 20, 40, -1, 0, 0, PI/2, 2);
  ambientLight(30,30,30);
  shape(moon,width/2,height/2);
  shape(s,width/2,height/2);

}
