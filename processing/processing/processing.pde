// - Osc handling... 
//
//FORM: TERRAIN --> STARS --> SYNCHRONIZED OBJECTS --> EARTH+MOON
//
//TRANSITIONS: tint the graphics with some opacity...tint(255,225);
//
// 1 -> 3 -> 2 -> 6 -> 4 -> 12 -> 8
// [0001]->[0011]->[0010]->[0110]->[0100]->[1100]->[1000]

import oscP5.*;
import java.lang.Math;
import netP5.*;

final static int TERRAIN = 1, STARS = 2, SYNCHRONIZED = 4, EARTHMOON = 8; 
final static int [] ORDERED_STATES = {1,3,2,6,4,/*12,*/8}; //JUMP STRAIGHT TO EARTHMOON

// OPTIONS 
final static int PIXEL_DENSITY = 1, OSC_PORT = 7700; 
final static Boolean OSC_ENABLED = true, NO_FULLSCREEN = true; 
final static String IP = "localhost"; //"192.168.2.2"

OscP5 oscP5;
NetAddress netAddr;
int currentStageIndex = 0;

int terrainOpacity = 0, starsOpacity = 0, syncOpacity = 0, earthOpacity = 0;
float starHue = 0.0;
Terrain movingTerrain;
Earthmoon earthMoon;
Stars stars;
Synchronized sync;

public void settings() {
    if(!NO_FULLSCREEN) fullScreen(P3D);
    else size(600, 400, P3D);
    pixelDensity(PIXEL_DENSITY);
}

void setup(){
    noCursor();
    frameRate(25);

    if(OSC_ENABLED){
        oscP5 = new OscP5(this, OSC_PORT);
        netAddr = new NetAddress(IP, OSC_PORT);//raspi ip 192.168.2.2
    }

    movingTerrain = new Terrain(width, height);
    stars = new Stars(width, height);
    earthMoon = new Earthmoon(width, height);
    sync = new Synchronized(width, height);

    hint(DISABLE_DEPTH_TEST); //needed?
    starsOpacity = 255;//temporary
    earthOpacity = 255;//temporary
}

void draw(){
    background(0); //black background
    int currentStage = ORDERED_STATES[currentStageIndex];
    Boolean terrainRunning = (TERRAIN&currentStage)>0, starsRunning = (STARS&currentStage)>0, syncRunning = (SYNCHRONIZED&currentStage)>0, earthRunning = (EARTHMOON&currentStage)>0;

    if(terrainRunning){
        tint(255, terrainOpacity);
        image(movingTerrain.drawTerrain(), 0, 0);
    }

    if(starsRunning){
        tint(lerpColor(Stars.STAR_COLOR, Stars.STAR_HUE, constrain(starHue,0,1)), starsOpacity); //change hue....
        if(terrainRunning)
            image(stars.drawStars(movingTerrain.getPoints()), 0, 0);
        else image(stars.drawStars(), 0, 0);
    }

    if(syncRunning){
        tint(255, currentStage == SYNCHRONIZED ? 255 : syncOpacity);
        image(sync.drawSynchronized(), 0, 0);
    }

    if(earthRunning){
        tint(255, earthOpacity);
        image(earthMoon.drawEarthmoon(), 0, 0);
    }

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
                    movingTerrain.setFlySpeed(msg.get(0).floatValue());
                break; 
            case "/terrainFade" :   
                if(msg.checkTypetag("i"))
                    terrainOpacity = msg.get(0).intValue();
                break; 
            case "/prevStage" :
                currentStageIndex = Math.floorMod(currentStageIndex-1,ORDERED_STATES.length);
                break;
            case "/nextStage" :
                currentStageIndex = (currentStageIndex+1)%ORDERED_STATES.length;
                break;
            case "/triggered" :
                sync.moveMoon();
                break;
            case "/starHue" :
                if(msg.checkTypetag("i"))
                    starHue = map(((float)msg.get(0).intValue()), 0, 127, 0, 1);
                break;
            case "/starsTransition":
                if(msg.checkTypetag("i") && ORDERED_STATES[currentStageIndex] == STARS + SYNCHRONIZED){
                    starsOpacity = (int)map(msg.get(0).intValue(), 0, 64, 255, 0);
                    syncOpacity = (int)map(msg.get(0).intValue(), 0, 64, 0, 255);
                }
                break;
            case "/moireAngle" :
                if(msg.checkTypetag("i"))
                    stars.setNewAngle(map(((float)msg.get(0).intValue()), 0, 127, -0.01, 0.03));
                break;
        }
        //FOR DEBUGGING
        //println(terrainOpacity); 
    }catch(Exception e){
        println(e); 
    }
}
