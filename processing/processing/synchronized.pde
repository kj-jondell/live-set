class Synchronized {
    private final static int MOON_SIZE = 24;

    float y = height, x = width, z = 0;
    float scalefactor = 1;
    float lightscale = 0.2;

    PGraphics sGraphics;
    PShape moon; 

    Synchronized(int sWidth, int sHeight){
        this.sGraphics = createGraphics(sWidth, sHeight, P3D);
        this.sGraphics.noStroke();
        this.sGraphics.smooth();

        this.moon = this.sGraphics.createShape(SPHERE, MOON_SIZE);
        this.moon.setTexture(loadImage("moon.jpg"));
    } 

    float a=0, angl=0;
    PGraphics drawSynchronized(){
        if(lightscale<1)
            lightscale += 0.001;
        angl = (angl+0.01)%TWO_PI;

        this.sGraphics.beginDraw();
        this.sGraphics.clear();

        this.sGraphics.lights();
        this.sGraphics.directionalLight(255,255,255, -1,0.25,0);
        //this.sGraphics.ambientLight(222*lightscale,222*lightscale,222*lightscale);
        this.sGraphics.translate(map(this.x, 0,width,-width/2+a,width/2-a),map(this.y, 0,height,-height/2+a,height/2-a),this.z);

        this.moon.rotate(angl, 0, 0, 1);
        this.sGraphics.shape(this.moon);
        this.sGraphics.endDraw();
        
        return this.sGraphics;
    }
}
