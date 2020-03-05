// - Osc handling... 
//
//FORM: TERRAIN --> STARS --> SYNCHRONIZED OBJECTS --> EARTH+MOON
//
//TRANSITIONS: tint the graphics with some opacity...tint(255,225);

import oscP5.*;
import netP5.*;

// OPTIONS 
final static int PIXEL_DENSITY = 2, OSC_PORT = 6543; 
final static Boolean OSC_ENABLED = true, NO_FULLSCREEN = true; 

OscP5 oscP5;
NetAddress netAddr;

Terrain movingTerrain;

public void settings() {
    if(NO_FULLSCREEN)
        size(600, 400, "processing.opengl.PGraphics3D");
    pixelDensity(PIXEL_DENSITY);
}

void setup(){
    if(!NO_FULLSCREEN) fullScreen(P3D);

    noCursor();

    if(OSC_ENABLED){
        oscP5 = new OscP5(this, OSC_PORT);
        netAddr = new NetAddress("localhost", OSC_PORT);//raspi ip 192.168.2.2
    }

    movingTerrain = new Terrain(width, height);

    hint(DISABLE_DEPTH_TEST); //needed?
}

void draw(){
    background(0); //black background
    image(movingTerrain.drawTerrain(), 0, 0);
}

/*
 * Handling OSC Events...
 */
void oscEvent(OscMessage msg){
    try{
        switch(msg.addrPattern()){
            case "/terrainHeight" :   
                if(msg.checkTypetag("fi"));
                break; 
            case "/flySpeed" :   
                if(msg.checkTypetag("fi"));
                break; 
        }
    }catch(Exception e){
        println(e); 
    }
}
