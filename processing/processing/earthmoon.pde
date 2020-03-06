class Earthmoon {

    private final static int EARTH_SIZE = 150, MOON_SIZE = 24;

    PGraphics eGraphics;
    PShape earth, moon;

    int eWidth, eHeight;

    /*
     * Terrain scene 
     */
    Earthmoon(int eWidth, int eHeight){
        this(eWidth, eHeight, createGraphics(eWidth, eHeight, P3D));
    }

    Earthmoon(int eWidth, int eHeight, PGraphics eGraphics){
        this.eGraphics = eGraphics;

        this.eWidth = eWidth;
        this.eHeight = eHeight;

        this.eGraphics.perspective();
        this.eGraphics.noStroke();
        this.eGraphics.smooth();
        
        this.earth = this.eGraphics.createShape(SPHERE, EARTH_SIZE);
        this.moon = this.eGraphics.createShape(SPHERE, MOON_SIZE);
        this.moon.translate(0,0,300);

        this.earth.setTexture(loadImage("earth2.jpg"));
        this.moon.setTexture(loadImage("moon.jpg"));

        this.eGraphics.perspective();
    }

    PGraphics drawEarthmoon(){
        this.eGraphics.beginDraw();
        this.eGraphics.clear();

        this.moon.rotate(0.002,0,1,0);
        this.earth.rotate(0.002,0,1,0);

        this.eGraphics.directionalLight(255,255,255, -1,0.25,0);
        this.eGraphics.ambientLight(120,120,120); // NEEDED ? DOES N'T WORK SEEMINGLY...
        this.eGraphics.shape(this.moon, this.eWidth/2, this.eHeight/2);
        this.eGraphics.shape(this.earth, this.eWidth/2, this.eHeight/2);

        this.eGraphics.endDraw();

        return this.eGraphics; 
    }

}
