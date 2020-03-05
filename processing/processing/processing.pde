// - Osc handling... 
//
//FORM: TERRAIN --> STARS --> SYNCHRONIZED OBJECTS --> EARTH+MOON
//
//TRANSITIONS: tint the graphics with some opacity...tint(255,225);
//
// 1 -> 3 -> 2 -> 6 -> 4 -> 12 -> 8
// [0001]->[0011]->[0010]->[0110]->[0100]->[1100]->[1000]

import oscP5.*;
import netP5.*;

final static int TERRAIN = 1, STARS = 2, SYNCHRONIZED = 4, EARTHMOON = 8; 
final static int [] ORDERED_STATES = {1,3,2,6,4,12,8};

// OPTIONS 
final static int PIXEL_DENSITY = 2, OSC_PORT = 6541; 
final static Boolean OSC_ENABLED = true, NO_FULLSCREEN = true; 
final static float FLY_SCALE = 100;
final static String IP = "localhost";//"192.168.2.2";

OscP5 oscP5;
NetAddress netAddr;
int currentStageIndex = 0;

int terrainOpacity = 0, starsOpacity = 0;
Terrain movingTerrain;
Stars stars;

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
    stars = new Stars(width, height);

    hint(DISABLE_DEPTH_TEST); //needed?
    starsOpacity = 255;//temporary
}

Boolean first = true; //TODO remove
void draw(){
    background(0); //black background
    int currentStage = ORDERED_STATES[currentStageIndex];
    if((TERRAIN&currentStage)>0){
        tint(255, terrainOpacity);
        image(movingTerrain.drawTerrain(), 0, 0);
    }

    if((STARS&currentStage)>0){
        tint(255, starsOpacity); //OWN OPACITY
        image(stars.drawStars((TERRAIN&currentStage)>0? movingTerrain.getPoints() : null), 0, 0);
    }

    if((SYNCHRONIZED&currentStage)>0){
    }

    if((EARTHMOON&currentStage)>0){
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
                    movingTerrain.setFlySpeed(msg.get(0).floatValue()/FLY_SCALE);
                break; 
            case "/terrainFade" :   
                if(msg.checkTypetag("i"))
                    terrainOpacity = msg.get(0).intValue();
                break; 
            case "/prevStage" :
                currentStageIndex = (currentStageIndex-1)%ORDERED_STATES.length;
                break;
            case "/nextStage" :
                currentStageIndex = (currentStageIndex+1)%ORDERED_STATES.length;
                break;
        }
        //FOR DEBUGGING
        //println(terrainOpacity); 
    }catch(Exception e){
        println(e); 
    }
}
