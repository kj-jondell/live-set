class Terrain { //TODO: extends PGraphics 
    final static int SCALE = 15;
    float triangleOpacity = 0.2;

    int columns, rows;
    float flying, flySpeed, tHeight;
    float[][] coordinates;

    ArrayList <PVector> points;
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
        this.points = new ArrayList<PVector>();
    }

    /*
     * Helper methodfor generating terrain
     */
    private void generateTerrain(){
        this.flying -= this.flySpeed;
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
        this.tGraphics.background(0);

        this.generateTerrain();

        this.tGraphics.rotateX(PI/4);
        for (int y=0; y < this.rows-1; y++){
            this.tGraphics.beginShape(TRIANGLE_STRIP);
            for (int x=0; x < this.columns; x++) {
                this.tGraphics.strokeWeight(1);
                this.tGraphics.stroke(map(this.coordinates[x][y], 0, 100, 150, 255), 125, 255, map(y, 0, this.rows, 0, 255)*(this.triangleOpacity));//LIGHTNING :random(10000)>9900?1:0.1

                PVector v1 = new PVector(x*this.SCALE, y*this.SCALE, this.coordinates[x][y]);
                PVector v2 = new PVector(x*this.SCALE, (y+1)*this.SCALE, this.coordinates[x][y+1]);

                this.tGraphics.vertex(v1.x, v1.y, v1.z);
                this.tGraphics.vertex(v2.x, v2.y, v2.z);

                this.points.add(v1);
                this.points.add(v2);
            }
            this.tGraphics.endShape();
        }

        for (PVector v : this.points){
            this.tGraphics.strokeWeight(2);
            this.tGraphics.stroke(255);
            this.tGraphics.point(v.x, v.y, v.z);
        }

        this.tGraphics.endDraw();
        return this.tGraphics;
    }

    void setFlySpeed(float flySpeed){
        this.flySpeed = flySpeed;
    }

    void setTerrainHeight(float terrainHeight){
        this.terrainHeight = terrainHeight;
    }

    /*
     * Vertex points...
     */
    ArrayList<PVector> getPoints(){
        return this.points;
    }
}
