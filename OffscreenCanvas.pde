// note, I tried to make this flexible enough to work for SVG and PDF, 
// but ran into numerous errors that make me thing that if you want to use SVG or PDF, 
// it does not make sense to do so in an offscreen canvas.

public class OffscreenCanvas {
  PGraphics graphics;
  PGraphics offscreen3d;
  
  OffscreenCanvas(int width, int height) {
    graphics = createGraphics(width, height, P3D);
    offscreen3d = createGraphics(width, height, P3D);
  }
  
  OffscreenCanvas(PGraphics svg) {
    graphics = svg;
    offscreen3d = createGraphics(svg.width, svg.height, P3D);
  }
  
  void clear() {
    graphics.clear();
    graphics.beginDraw();
    graphics.background(255);
    graphics.endDraw();
    
    offscreen3d.clear();
  }
  
  void saveImage(String name){
    PImage crop = graphics.get(0, 0, graphics.width, graphics.height);
    crop.save(name+".png");
  }
  
  void preDraw3d(){
    offscreen3d.beginDraw();

    // set up 3d scene
    if (parameters.cp5.getController("ortho").getValue()==1.0) offscreen3d.ortho();
    else offscreen3d.perspective();
    offscreen3d.pushMatrix();
    offscreen3d.noStroke();
    offscreen3d.lights();
    offscreen3d.translate(offscreen3d.width/2, offscreen3d.width/2, 0);
    offscreen3d.scale(parameters.cp5.getController("sceneScale").getValue());
    offscreen3d.rotateX(camRotationX);
    offscreen3d.rotateY(camRotationY);
  }
  
  void postDraw3d(){
    offscreen3d.popMatrix();
    offscreen3d.endDraw();
  }
  
  // start functions for rendering 3d objects to 2d SVG. 
  
  // TODO: modify to make continuous lines part of one shape
  void drawBox(float size){
    // make 8 vertexes to map to 8 2d points
    PVector p1 = new PVector(-size/2,-size/2,-size/2);
    PVector p2 = new PVector(size/2,-size/2,-size/2);
    PVector p3 = new PVector(-size/2,-size/2,size/2);
    PVector p4 = new PVector(size/2,-size/2,size/2);
    PVector p5 = new PVector(-size/2,size/2,-size/2);
    PVector p6 = new PVector(size/2,size/2,-size/2);
    PVector p7 = new PVector(-size/2,size/2,size/2);
    PVector p8 = new PVector(size/2,size/2,size/2);
    
    PVector p12d = new PVector(offscreen3d.screenX(p1.x,p1.y,p1.z), offscreen3d.screenY(p1.x,p1.y,p1.z));
    PVector p22d = new PVector(offscreen3d.screenX(p2.x,p2.y,p2.z), offscreen3d.screenY(p2.x,p2.y,p2.z));
    PVector p32d = new PVector(offscreen3d.screenX(p3.x,p3.y,p3.z), offscreen3d.screenY(p3.x,p3.y,p3.z));
    PVector p42d = new PVector(offscreen3d.screenX(p4.x,p4.y,p4.z), offscreen3d.screenY(p4.x,p4.y,p4.z));
    PVector p52d = new PVector(offscreen3d.screenX(p5.x,p5.y,p5.z), offscreen3d.screenY(p5.x,p5.y,p5.z));
    PVector p62d = new PVector(offscreen3d.screenX(p6.x,p6.y,p6.z), offscreen3d.screenY(p6.x,p6.y,p6.z));
    PVector p72d = new PVector(offscreen3d.screenX(p7.x,p7.y,p7.z), offscreen3d.screenY(p7.x,p7.y,p7.z));
    PVector p82d = new PVector(offscreen3d.screenX(p8.x,p8.y,p8.z), offscreen3d.screenY(p8.x,p8.y,p8.z));
    
    drawCroppedLine(p12d, p22d);
    drawCroppedLine(p12d, p32d);
    drawCroppedLine(p32d, p42d);
    drawCroppedLine(p42d, p22d);
    
    drawCroppedLine(p52d, p62d);
    drawCroppedLine(p52d, p72d);
    drawCroppedLine(p72d, p82d);
    drawCroppedLine(p82d, p62d);

    drawCroppedLine(p12d, p52d);
    drawCroppedLine(p22d, p62d);
    drawCroppedLine(p32d, p72d);
    drawCroppedLine(p42d, p82d);
  }
  
  void draw3dBezier(PVector anchor1, PVector control1, PVector control2, PVector anchor2){
    int steps = 2 + int(10 * controls.cp5.getController("curveFidelity").getValue()); // need minimum of 2 segments;
    
    graphics.beginShape();
    
    float previousX = 0;
    float previousY = 0;
    
    Boolean newCurve = true;
    Boolean firstLineDrawn = false;
    
    // TODO: abstract this to take a list of 2d vertexes and draw them properly with cropping, etc. to be used by anything.
    for (int s = 0; s <= steps; s++) {
      float t = s / float(steps);
      
      float x = bezierPoint(anchor1.x, control1.x, control2.x, anchor2.x, t);
      float y = bezierPoint(anchor1.y, control1.y, control2.y, anchor2.y, t);
      float z = bezierPoint(anchor1.z, control1.z, control2.z, anchor2.z, t);

      float sX = offscreen3d.screenX(x,y,z);
      float sY = offscreen3d.screenY(x,y,z);
      
      if (newCurve == false){
        // skip duplicate vertexes
        if(sX != previousX || sY != previousY) {
          // See if crop is needed and to which side
          int offScreenPoints = offscreenPoints(new PVector(previousX, previousY), new PVector(sX, sY));

          ArrayList<PVector> croppedLine = cropLine(new PVector(previousX, previousY), new PVector(sX, sY));
          if (croppedLine!=null){
            // capture the first vertex if this is s 1
            if(firstLineDrawn == false) {
              graphics.vertex(croppedLine.get(0).x, croppedLine.get(0).y);
              firstLineDrawn = true;
            }
            
            graphics.vertex(croppedLine.get(1).x, croppedLine.get(1).y);
           
            previousX = croppedLine.get(1).x;
            previousY = croppedLine.get(1).y;
            
            if (offScreenPoints == 1){
              // the first point is offscreen, continue adding vertexes from here
            } if (offScreenPoints == 2 || offScreenPoints == 3 ){ 
              // the second point is offscreen, the restart the line
              firstLineDrawn = false;
              previousX = sX;
              previousY = sY;
              //println("ending shape, cropped line");
              graphics.endShape();
              graphics.beginShape();
            }
          }
        } 
      } else {
        newCurve = false;
        previousX = sX;
        previousY = sY;
      }

    }
    graphics.endShape();
  }
  
  
  // start line cropping utilities.
  
  void drawCroppedLine(PVector point1, PVector point2){
    ArrayList<PVector> croppedLine = cropLine(point1, point2);
    if (croppedLine!=null) graphics.line(croppedLine.get(0).x, croppedLine.get(0).y, croppedLine.get(1).x, croppedLine.get(1).y);
  }
  
  int offscreenPoints(PVector point1, PVector point2){
    if (    (point1.x >= offscreenCanvasMargin && point1.x <= graphics.width-offscreenCanvasMargin && point1.y >= offscreenCanvasMargin && point1.y <= graphics.height-offscreenCanvasMargin)
         && (point2.x >= offscreenCanvasMargin && point2.x <= graphics.width-offscreenCanvasMargin && point2.y >= offscreenCanvasMargin && point2.y <= graphics.height-offscreenCanvasMargin) )  {
      // both of the two points are inside the margins
      return 0;
    } else if (    (point1.x >= offscreenCanvasMargin && point1.x <= graphics.width-offscreenCanvasMargin && point1.y >= offscreenCanvasMargin && point1.y <= graphics.height-offscreenCanvasMargin)
         || (point2.x >= offscreenCanvasMargin && point2.x <= graphics.width-offscreenCanvasMargin && point2.y >= offscreenCanvasMargin && point2.y <= graphics.height-offscreenCanvasMargin) )  {
      // one or the other of the two points are inside the margins
      
      if ((point1.x <= offscreenCanvasMargin && point2.x > offscreenCanvasMargin) || (point2.x <= graphics.width-offscreenCanvasMargin && point1.x > graphics.width-offscreenCanvasMargin)) return 1;
      if ((point2.x <= offscreenCanvasMargin && point1.x > offscreenCanvasMargin) || (point1.x <= graphics.width-offscreenCanvasMargin && point2.x > graphics.width-offscreenCanvasMargin)) return 2;
      if ((point1.y <= offscreenCanvasMargin && point2.y > offscreenCanvasMargin) || (point2.y <= graphics.height-offscreenCanvasMargin && point1.y > graphics.height-offscreenCanvasMargin)) return 1;
      if ((point2.y <= offscreenCanvasMargin && point1.y > offscreenCanvasMargin) || (point1.y <= graphics.height-offscreenCanvasMargin && point2.y > graphics.height-offscreenCanvasMargin)) return 2;
            
      return -1;
    } else {
      // both of the two points are outside the margins
      return 3;
    }
  }
  
  ArrayList<PVector> cropLine(PVector point1, PVector point2){
    ArrayList<PVector> result = new ArrayList<PVector>();
   
    // line 1
    float x1 = point1.x;    
    float y1 = point1.y;
    float x2 = point2.x;   
    float y2 = point2.y;
    
    // left side of paper 2
    float x3 = offscreenCanvasMargin;  
    float y3 = 0;
    float x4 = offscreenCanvasMargin;
    float y4 = graphics.height;
    
    float uA = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1)); // distance along line 1 where it intersects line 2
    float uB = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
    
    // if uA and uB are between 0-1, lines are colliding
    if (uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1) {
      float intersectionX = x1 + (uA * (x2-x1));
      float intersectionY = y1 + (uA * (y2-y1));
      
      if (x1<x2){
        x1 = intersectionX;
        y1 = intersectionY;
      } else {
        x2 = intersectionX;
        y2 = intersectionY;
      }
    }  
    
    // right side of paper 2
    x3 = graphics.width-offscreenCanvasMargin;  
    y3 = 0;
    x4 = graphics.width-offscreenCanvasMargin;
    y4 = graphics.height;
    
    uA = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1)); // distance along line 1 where it intersects line 2
    uB = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
    
    // if uA and uB are between 0-1, lines are colliding
    if (uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1) {
      float intersectionX = x1 + (uA * (x2-x1));
      float intersectionY = y1 + (uA * (y2-y1));
      
      if (x1<x2){
        x2 = intersectionX;
        y2 = intersectionY;
      } else {
        x1 = intersectionX;
        y1 = intersectionY;
      }
      
    }  
    
    // top of paper 2
    x3 = 0;  
    y3 = offscreenCanvasMargin;
    x4 = graphics.width;
    y4 = offscreenCanvasMargin;
    
    uA = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1)); // distance along line 1 where it intersects line 2
    uB = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
    
    // if uA and uB are between 0-1, lines are colliding
    if (uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1) {
      float intersectionX = x1 + (uA * (x2-x1));
      float intersectionY = y1 + (uA * (y2-y1));
      
      if (y1<y2){
        x1 = intersectionX;
        y1 = intersectionY;
      } else {
        x2 = intersectionX;
        y2 = intersectionY;
      }
      
    }  
    
    // bottom of paper 2
    x3 = 0;  
    y3 = graphics.height-offscreenCanvasMargin;
    x4 = graphics.width;
    y4 = graphics.height-offscreenCanvasMargin;
    
    uA = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1)); // distance along line 1 where it intersects line 2
    uB = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));
    
    // if uA and uB are between 0-1, lines are colliding
    if (uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1) {
      float intersectionX = x1 + (uA * (x2-x1));
      float intersectionY = y1 + (uA * (y2-y1));
      
      if (y1<y2){
        x2 = intersectionX;
        y2 = intersectionY;
      } else {
        x1 = intersectionX;
        y1 = intersectionY;
      }
    }  
    
    if (offscreenPoints(new PVector(x1,y1), new PVector(x2,y2)) == 3){
      // cropped results are now entirely outside of bounds
      return null;
    } else {
      // return uncropped points
      result.add(new PVector(x1,y1));
      result.add(new PVector(x2,y2));
      return result;
    }
  }
}