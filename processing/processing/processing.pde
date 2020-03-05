// - Osc handling... 
//
//FORM: TERRAIN --> STARS --> SYNCHRONIZED OBJECTS --> EARTH+MOON
//
//TRANSITIONS: tint the graphics with some opacity...tint(255,225);

import oscP5.*;
import netP5.*;

// OPTIONS 
final static int PIXEL_DENSITY = 2; 
final static Boolean OSC_ENABLED = false; 

OscP5 oscP5;
NetAddress netAddr;

Terrain movingTerrain;

void setup(){
    fullScreen(P3D);
    noCursor();
    pixelDensity(PIXEL_DENSITY);

    if(OSC_ENABLED){
        oscP5 = new OscP5(this, 7771);
        netAddr = new NetAddress("localhost", 7771);//raspi ip 192.168.2.2
    }

    movingTerrain = new Terrain(width, height);

    hint(DISABLE_DEPTH_TEST); //needed?
}

void draw(){
    background(0); //black background
    image(movingTerrain.drawTerrain(), 0, 0);
}
