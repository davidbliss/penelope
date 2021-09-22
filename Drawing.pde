// For convinience, all drawing things are consolidated here

public class Drawing{
  Parameters parameters;

  Drawing(Parameters parameters){
    this.parameters = parameters;
  }

  public void generate(){
    
  }

  public void draw(ArrayList<PenelopeCanvas> layers){
    
    PenelopeCanvas canvas = layers.get(0);
    canvas.preDraw3d();
    
    canvas.graphics.beginDraw();
    canvas.graphics.stroke(colors.colors[0], 255);
    canvas.graphics.strokeWeight(3);
    canvas.graphics.strokeCap(ROUND);
    canvas.graphics.noFill();
    
    float boxSize = 162.5;
    int numCols = int(parameters.cp5.getController("numCols").getValue()) + 1; //6;
    int numRows = int(parameters.cp5.getController("numRows").getValue()) + 1; //9;
    float zShift = parameters.cp5.getController("offsetZ").getValue();
    
    canvas.graphics.stroke(color(255,0,0));
    
    canvas.offscreen3d.translate(-boxSize*numCols/2, -boxSize*(numRows-1)*zShift, -boxSize*numCols/2);
    
    canvas.offscreen3d.pushMatrix();
    for (int r = 0; r < numRows; r++){
      canvas.offscreen3d.translate(0, boxSize, boxSize);
      for (int c = 0; c < numCols; c++){
        drawBoxTile(canvas, boxSize, r==0, c==0, c==numCols-1, r==numRows-1, r%2==1);
        canvas.offscreen3d.translate(boxSize, 0, boxSize);
      }
      canvas.offscreen3d.translate(-boxSize*(numCols+((r+1)%2)), 0, -boxSize*(numCols+((r+1)%2)));
    }
   
    canvas.graphics.stroke(color(0));
    
    if (layers.size()>1){
      canvas.graphics.endDraw();
      canvas.postDraw3d();
      canvas = layers.get(1);
    }
    
    canvas.graphics.beginDraw();
    canvas.graphics.stroke(colors.colors[1], 255);
    canvas.graphics.strokeWeight(3);
    canvas.graphics.strokeCap(ROUND);
    canvas.graphics.noFill();
    canvas.sign();
    canvas.graphics.endDraw();
  }

  void drawBoxTile(PenelopeCanvas canvas, float size, boolean top, boolean left, boolean right, boolean bottom, boolean oddRow){
    // make 8 vertexes to map to 8 2d points
    PVector p0 = new PVector(-size/2,-3*size/2,-size/2);
    PVector p1 = new PVector(-size/2,-size/2,-size/2);
    PVector p2 = new PVector(size/2,-size/2,-size/2);
    PVector p3 = new PVector(-size/2,-size/2,size/2);
    PVector p4 = new PVector(size/2,-size/2,size/2);
    PVector p5 = new PVector(-size/2,size/2,-size/2);
    PVector p6 = new PVector(size/2,size/2,-size/2);
    PVector p7 = new PVector(-size/2,size/2,size/2);
    PVector p8 = new PVector(size/2,size/2,size/2);

    PVector p02d = new PVector(canvas.offscreen3d.screenX(p0.x,p0.y,p0.z), canvas.offscreen3d.screenY(p0.x,p0.y,p0.z));
    PVector p12d = new PVector(canvas.offscreen3d.screenX(p1.x,p1.y,p1.z), canvas.offscreen3d.screenY(p1.x,p1.y,p1.z));
    PVector p32d = new PVector(canvas.offscreen3d.screenX(p3.x,p3.y,p3.z), canvas.offscreen3d.screenY(p3.x,p3.y,p3.z));
    PVector p42d = new PVector(canvas.offscreen3d.screenX(p4.x,p4.y,p4.z), canvas.offscreen3d.screenY(p4.x,p4.y,p4.z));
    PVector p52d = new PVector(canvas.offscreen3d.screenX(p5.x,p5.y,p5.z), canvas.offscreen3d.screenY(p5.x,p5.y,p5.z));
    PVector p72d = new PVector(canvas.offscreen3d.screenX(p7.x,p7.y,p7.z), canvas.offscreen3d.screenY(p7.x,p7.y,p7.z));
    PVector p82d = new PVector(canvas.offscreen3d.screenX(p8.x,p8.y,p8.z), canvas.offscreen3d.screenY(p8.x,p8.y,p8.z));

    if (top==false && left==false && right==false && bottom==false ){
      //println("standard");
      ArrayList<PVector> points = new ArrayList<PVector>();
      points.add(p02d);
      points.add(p12d);
      points.add(p32d);
      points.add(p42d);
      points.add(p82d);
      points.add(p72d);
      points.add(p52d);
      canvas.drawPolyline(points);
    } else if (top==true && left==false && right==false && bottom==false) {
      //println("top row");
      ArrayList<PVector> points = new ArrayList<PVector>();
      points.add(p12d);
      points.add(p32d);
      points.add(p42d);
      points.add(p82d);
      points.add(p72d);
      points.add(p52d);
      canvas.drawPolyline(points);
    } else if (left==true && right==false && bottom==false && oddRow==false) {
      //println("first column, evenRow");
      ArrayList<PVector> points = new ArrayList<PVector>();
      points.add(p32d);
      points.add(p42d);
      points.add(p82d);
      points.add(p72d);
      canvas.drawPolyline(points);
    } else if (left==true && right==false && bottom==false && oddRow==true) {
      //println("first column, oddRow");
      ArrayList<PVector> points = new ArrayList<PVector>();
      points.add(p42d);
      points.add(p82d);
      canvas.drawPolyline(points);
    } else if (top==true && left==false && right==true && bottom==false) {
      //println("last column, first row");
      ArrayList<PVector> points = new ArrayList<PVector>();
      points.add(p12d);
      points.add(p32d);
      points.add(p72d);
      points.add(p52d);
      canvas.drawPolyline(points);
    } else if (left==false && right==true && bottom==false && oddRow==false) {
      //println("last column, even row");
      ArrayList<PVector> points = new ArrayList<PVector>();
      points.add(p02d);
      points.add(p12d);
      points.add(p32d);
      points.add(p72d);
      points.add(p52d);
      canvas.drawPolyline(points);
    } else if (left==false && right==true && bottom==false && oddRow==true) {
      //println("last column, odd row");
      ArrayList<PVector> points = new ArrayList<PVector>();
      points.add(p02d);
      points.add(p12d);
      points.add(p32d);
      points.add(p42d);
      points.add(p82d);
      points.add(p72d);
      points.add(p52d);
      canvas.drawPolyline(points);
    } else if (top==false && left==false && bottom==true) {
      //println("last row");
      ArrayList<PVector> points = new ArrayList<PVector>();
      points.add(p02d);
      points.add(p12d);
      canvas.drawPolyline(points);
    }
  }
}
