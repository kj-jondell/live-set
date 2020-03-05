class Stars {

    private final static color STAR_COLOR = #FFFFFF;
    private final static float AMT_LEVELS = 1;

    PGraphics sGraphics;
    ArrayList<TPoint> stars;

    //float alpha= 0, alpha_incr=0.5, AMT_LEVELS = 50, incr = 0.01;
    //int pixelScalar = 1, amtDots = 1000;

    Stars(int sWidth, int sHeight){
        sGraphics = createGraphics(sWidth, sHeight, P3D);
    }

    PGraphics drawStars(){
        this.sGraphics.beginDraw();
        this.sGraphics.clear();
        //this.sGraphics.rotateX(PI/4);

        this.drawPoints(this.stars);
        this.moireRotation();
        this.sGraphics.endDraw();
        return this.sGraphics;
    }

    PGraphics drawStars(ArrayList<TPoint> stars){
        this.sGraphics.beginDraw();
        this.sGraphics.clear();
        this.sGraphics.rotateX(PI/4);

        this.drawPoints(stars);
        this.sGraphics.endDraw();

        this.stars = stars;
        return this.sGraphics;
    }

    private void moireRotation(){
        int ind = 0;
        for (TPoint star : this.stars)
        {
            PVector p = star.coordinate;
            p.y -= height/2;
            p.x -= width/2;
            //OPTIMIZE THIS (not necessary with so many levels for points close to origin of rotation

            float new_a = -0.015;//PI/3;
            float new_y = (p.y*cos(new_a) - p.x*sin(new_a))*0.99; 
            float new_x = (p.y*sin(new_a) + p.x*cos(new_a))*0.99;
            float new_z = p.z*0.95;

            new_y += height/2;
            new_x += width/2;
            this.sGraphics.point(new_x,new_y,new_z);
            this.sGraphics.strokeWeight(2);

            if (star.coordinate.dist(new PVector(0,0,0))<1)
                star.coordinate = PVector.random3D().mult(width);
            else 
                star.coordinate = new PVector(new_x,new_y, new_z);

            ind++;
        }
    }

    private void generatePixel(){
        int x = (int)random(2*width)-width/2; //translate to move center of rotation
        int y = (int)random(2*width)-width/2; //translate to move center of rotation
        this.stars.add(new TPoint(new PVector(x,y,random(500)), STAR_COLOR));
        point(x, y, 0);
    }

    /*
     * Helper method
     */
    private void drawPoints(ArrayList<TPoint> stars){
        try{
            for (TPoint p : stars){
                PVector v = p.coordinate;
                this.sGraphics.point(v.x, v.y, v.z);
                this.sGraphics.strokeWeight(2);
                this.sGraphics.stroke(255, p.opacity);
            }
        } catch (NullPointerException e){
            println(e);
        }
    }

}
