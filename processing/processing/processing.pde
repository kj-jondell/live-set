// - Osc handling... 
//
//FORM: TERRAIN --> STARS --> SYNCHRONIZED OBJECTS --> EARTH+MOON
//
//TRANSITIONS: tint the graphics with some opacity...tint(255,225);

import oscP5.*;
import netP5.*;

// OPTIONS 
final static int PIXEL_DENSITY = 2, OSC_PORT = 6542; 
final static Boolean OSC_ENABLED = true, NO_FULLSCREEN = true; 
final static float FLY_SCALE = 100;

OscP5 oscP5;
NetAddress netAddr;

int terrainOpacity = 0;
Terrain movingTerrain;

public void settings() {
    if(!NO_FULLSCREEN) fullScreen(P3D);
    else size(600, 400, P3D);
    pixelDensity(PIXEL_DENSITY);
}

void setup(){
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
    tint(255, terrainOpacity);
    image(movingTerrain.drawTerrain(), 0, 0);
}

/*
 * Handling OSC Events...
 */
void oscEvent(OscMessage msg){
    try{
        switch(msg.addrPattern()){
            case "/terrainHeight" :   
                if(msg.checkTypetag("i"))
                    movingTerrain.setTerrainHeight(msg.get(0).intValue());
                break; 
            case "/flySpeed" :   
                if(msg.checkTypetag("f"))
                    movingTerrain.setFlySpeed(msg.get(0).floatValue()/FLY_SCALE);
                break; 
            case "/terrainFade" :   
                if(msg.checkTypetag("i"))
                    terrainOpacity = msg.get(0).intValue();
                break; 
        }
    }catch(Exception e){
        println(e); 
    }
}
