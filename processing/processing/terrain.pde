class Terrain { //TODO: extends PGraphics 
    final static int SCALE = 15;
    final static float FLY_SCALE = 100;

    int columns, rows;
    float flying, flySpeed, tHeight;
    float[][] coordinates;

    ArrayList <TPoint> points;
    PGraphics tGraphics;

    /*
     * Terrain scene 
     */
    Terrain(int sWidth, int sHeight){
        this(sWidth, sHeight, createGraphics(sWidth, sHeight, P3D));
    }

    Terrain(int sWidth, int sHeight, PGraphics graphics){
        this.tGraphics = graphics;

        this.columns = sWidth/SCALE; 
        this.rows = sHeight/SCALE;

        this.coordinates = new float[columns][rows]; 
        this.flying = 0;
        this.tHeight = 0;
        this.flySpeed = 0;
        this.points = new ArrayList<TPoint>();
    }

    /*
     * Helper methodfor generating terrain
     */
    private void generateTerrain(){
        this.flying -= this.flySpeed/FLY_SCALE;
        float yOffset = this.flying;
        for (int y=0; y < this.rows; y++) {
            float xOffset = 0;
            for (int x=0; x < this.columns; x++) {
                this.coordinates[x][y] = map(noise(xOffset, yOffset), 0, 1, -this.tHeight, this.tHeight);
                xOffset += 0.1;
            } 
            yOffset += 0.1;
        }
    }

    /*
     * Drawing method for scene...
     */
    PGraphics drawTerrain(){
        this.tGraphics.beginDraw();
        this.tGraphics.noFill();
        this.tGraphics.clear();

        this.generateTerrain();

        this.tGraphics.rotateX(PI/4); // Set this with a variable
        int vectorCount = 0;
        for (int y=0; y < this.rows-1; y++){
            this.tGraphics.beginShape(TRIANGLE_STRIP);
            for (int x=0; x < this.columns; x++) {
                float opacity = map(y, 0, this.rows, 0, 255);
                this.tGraphics.strokeWeight(1);

                this.tGraphics.stroke(map(this.coordinates[x][y], 0, 100, 150, 255)+(155*this.flySpeed), map(this.tHeight, 0, 127, 100, 255), 255, opacity);//LIGHTNING :random(10000)>9900?1:0.1 AND change hue..

                PVector v1 = new PVector(x*this.SCALE, y*this.SCALE, this.coordinates[x][y]);
                PVector v2 = new PVector(x*this.SCALE, (y+1)*this.SCALE, this.coordinates[x][y+1]);

                this.tGraphics.vertex(v1.x, v1.y, v1.z);
                this.tGraphics.vertex(v2.x, v2.y, v2.z);

                if(this.points.size()<((this.rows-1)*(this.columns)*2)){
                    this.points.add(new TPoint(v1, opacity));
                    this.points.add(new TPoint(v2, opacity));
                } else {
                    this.points.get(vectorCount).setCoordinate(v1);
                    this.points.get(vectorCount+1).setCoordinate(v2);
                }
                vectorCount += 2;
            }
            this.tGraphics.endShape();
        }

        this.tGraphics.endDraw();
        return this.tGraphics;
    }

    void setFlySpeed(float flySpeed){
        this.flySpeed = flySpeed;
    }

    void setTerrainHeight(float terrainHeight){
        this.tHeight = terrainHeight;
    }

    /*
     * Vertex points...
     */
    ArrayList<TPoint> getPoints(){
        return this.points;
    }
}

public class TPoint {
    PVector coordinate;
    float opacity;

    TPoint(float x, float y, float opacity){
        this(x,y,0,opacity); 
    }

    TPoint(float x, float y, float z, float opacity){
        this(new PVector(x,y,z), opacity);
    }

    TPoint(PVector coordinate, float opacity){
        this.coordinate = coordinate;
        this.opacity = opacity;
    }

    void setCoordinate(PVector newCoordinate){
        this.coordinate = newCoordinate;
    }

}
