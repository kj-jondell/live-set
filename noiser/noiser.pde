/*
 * TODO: 1) clean code
 *      1b) make static variables
 * 2) osc mapping
 * 3) optimize 
 * 4) color palette
 *
 *
*/
import oscP5.*;
import netP5.*;

//Stellar colors, categories: OBAFGKM
//http://www.vendian.org/mncharity/dir3/starcolor/
final static color [] STELLARS = {#9BB0FF, #AABFFF, #CAD7FF, #F8F7FF, #FFF4EA, #FFD2A1, #FFCC6F};

OscP5 oscP5;
NetAddress netAddr;

PShape s, moon;
PImage img;

ArrayList<Pixel> coordinates = new ArrayList<Pixel>();
float alpha= 0, alpha_incr=0.5, levels = 50, incr = 0.01;
int pixelScalar = 1, amtDots = 1000;


void setup()
{
  fullScreen(P3D);
  noCursor();
  frameRate(15);
  noFill();
  smooth();
  noStroke();
  oscP5 = new OscP5(this, 2346);
  netAddr = new NetAddress("127.0.0.1", 2346);
  background(0);

    coordinates = new ArrayList<Pixel>();
    for (int index = 0; index<amtDots; index++){
        generatePixel();

    }

  s = createShape(SPHERE,30);
  moon = createShape(SPHERE,10);
  //s.scale(2);
  //img = loadImage("jup.jpg");
  img = loadImage("earth2.jpg");
  s.setTexture(img);
  moon.setTexture(loadImage("moon.jpg"));
  moon.translate(0,0,100);
}

void generatePixel(){
  color pixcol = STELLARS[(int)(random(STELLARS.length))];
  int x = (int)random(2*width)-width/2; //translate to move center of rotation
  int y = (int)random(2*width)-width/2; //translate to move center of rotation
  coordinates.add(new Pixel(x, y, pixcol));
  set(x,y,pixcol);
}

void oscEvent(OscMessage msg){
  if(msg.checkAddrPattern("/Velocity1")){
    try{
      if(msg.get(0).intValue()>88)
      blink = true;
    }catch(Exception e){
      println(msg.get(0));
      println(e); 
    }
  }
  if(msg.checkAddrPattern("/test")){
    try{
      a = msg.get(0).floatValue();
    }catch(Exception e){
      println(msg.get(0));
      println(e); 
    }
  }

}
  /*
   */

Boolean blink = false;
float newAlpha(float x, float y){
  if(blink){ //blinking...
    return 1.0;
  }
  return constrain(map(dist(x,y,width/2,height/2), 0, dist(width/3,height/3,width/2,height/2), 0.0, 1.0), 0.0,1.0);
}

float a=0.00,low_bound=0.25,hi_bound=1;
void draw()
{
    background(0);

     //TEMPORARY
     a += incr;
     if(a>=TWO_PI || a<= -TWO_PI)
     incr = -incr;

  
     for (int ind = 0; ind<coordinates.size(); ind++)
       {
         PVector p = coordinates.get(ind).coordinates;
         p.y -= height/2;
         p.x -= width/2;
         //OPTIMIZE THIS (not necessary with so many levels for points close to origin of rotation
         for (int level = 1; level<=levels; level++){
           float new_a = a/10000*level;
           float new_y = (p.y*cos(new_a) - p.x*sin(new_a))*constrain(map(dist(p.x,p.y,0,0), 0, dist(0,0,width/2,height/2), 0.96,0.98), low_bound, hi_bound); 
           float new_x = (p.y*sin(new_a) + p.x*cos(new_a))*constrain(map(dist(p.x,p.y,0,0),0, dist(0,0,width/2,height/2),  0.96,0.98), low_bound, hi_bound);
           new_y += height/2;
           new_x += width/2;
           color current = coordinates.get(ind).pixelColor ;
           float n_alpha = newAlpha(new_x,new_y);
           color newColor = color(red(current)*n_alpha,green(current)*n_alpha,blue(current)*n_alpha); 
           set((int)new_x,(int)new_y, newColor);

           if( level == levels )
           {
             coordinates.get(ind).coordinates = new PVector(new_x,new_y);
             if(dist(new_x,new_y,width/2,height/2)<=10)
             {
               coordinates.remove(ind);
               generatePixel();
             }
           }

         }
      }
//  filter(GRAY);
    blink = false;
    /*
       moon.rotate(0.01,0,1,0);

       s.rotate(0.01,0,0,1);
    //s.translate(0,0,0);
    directionalLight(255,255,255, -1,0.5,0);
    //spotLight(51, 102, 126, 80, 20, 40, -1, 0, 0, PI/2, 2);
    ambientLight(30,30,30);
    shape(moon,width/2,height/2);
    shape(s,width/2,height/2);
     */
}

class Pixel {
    PVector coordinates;
    color pixelColor;

    Pixel(float x, float y, color pixelColor){
      this.coordinates = new PVector(x,y);
      this.pixelColor = pixelColor;
    }

    Pixel(PVector coordinates, color pixelColor){
      this.coordinates = coordinates;
      this.pixelColor = pixelColor;
    }
}
