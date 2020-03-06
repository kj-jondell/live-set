class Synchronized {
    private final static int MOON_SIZE = 50;

    float y = height/2, x = width/2;
    float rotation = 0;

    PGraphics sGraphics;
    PShape moon; 

    PVector light = new PVector(-1,0.25,0);

    Synchronized(int sWidth, int sHeight){
        this.sGraphics = createGraphics(sWidth, sHeight, P3D);
        this.sGraphics.noStroke();
        this.sGraphics.smooth();

        this.moon = this.sGraphics.createShape(SPHERE, MOON_SIZE);
        this.moon.setTexture(loadImage("moon.jpg"));
    } 

    PGraphics drawSynchronized(){
        this.sGraphics.beginDraw();
        this.sGraphics.clear();

        //this.sGraphics.lights();
        this.sGraphics.directionalLight(255,255,255, this.light.x, this.light.y, this.light.z);
        //this.sGraphics.translate(map(this.x, 0,width,-width/2+a,width/2-a),map(this.y, 0,height,-height/2+a,height/2-a),this.z);

        this.moon.rotate(this.rotation, 0, 1, 0);
        if (this.rotation != 0)
            this.rotation = 0;
        this.sGraphics.shape(this.moon, this.x, this.y);
        this.sGraphics.endDraw();
        
        return this.sGraphics;
    }

    void moveMoon(){
        this.x = constrain(random(width), MOON_SIZE+15, width-MOON_SIZE-15);
        this.y = constrain(random(height), MOON_SIZE+15, height-MOON_SIZE-15);
        this.rotation = random(TWO_PI);
        light = PVector.random2D();
    }
}
