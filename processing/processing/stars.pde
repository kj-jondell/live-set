class Stars {

    PGraphics sGraphics;
    ArrayList<TPoint> stars;

    Stars(int sWidth, int sHeight){
        sGraphics = createGraphics(sWidth, sHeight, P3D);
    }

    /*
       Stars(ArrayList<TPoint> stars){
       this.stars = stars;
       }
     */

    PGraphics drawStars(){
        //...
        return this.sGraphics;
    }

    PGraphics drawStars(ArrayList<TPoint> stars){
        this.sGraphics.beginDraw();
        this.sGraphics.clear();
        this.sGraphics.rotateX(PI/4);
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
        this.sGraphics.endDraw();
        return this.sGraphics;
    }

}
