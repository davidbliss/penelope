// note, I tried to make this flexible enough to work for SVG and PDF, 
// but ran into numerous errors that make me thing that if you want to use SVG or PDF, 
// it does not make sense to do so in an offscreen canvas.

public class OffscreenCanvas {
  PGraphics graphics;
  Boolean isSVG;
  
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
  
  // TODO: add drawBox
  
  void draw3dBezier(PVector anchor1, PVector control1, PVector control2, PVector anchor2){
    int steps = 2 + int(10 * controls.cp5.getController("curveFidelity").getValue()); // need minimum of 2 segments;
    
    graphics.beginShape();
    
    float previousX = 0;
    float previousY = 0;
    
    Boolean newCurve = true;
    Boolean firstLineDrawn = false;
    
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
          if(offScreenPoints == 3){
            // ignore this line, both points are out bounds.
            // TODO: handle lines that are like this since they could cross over the page area.
            
            firstLineDrawn = false;
            previousX = sX;
            previousY = sY;
            graphics.endShape();
            graphics.beginShape();
          } else {
            ArrayList<PVector> croppedLine = cropLine(new PVector(previousX, previousY), new PVector(sX, sY));
            
            // capture the first vertex if this is s 1
            if(firstLineDrawn == false) {
              graphics.vertex(croppedLine.get(0).x, croppedLine.get(0).y);
              firstLineDrawn = true;
            }
            
            graphics.vertex(croppedLine.get(1).x, croppedLine.get(1).y);
           
            previousX = croppedLine.get(1).x;
            previousY = croppedLine.get(1).y;
            
            if (offScreenPoints == 0){
              // the first point is offscreen, continue adding vertexes from here
            } if (offScreenPoints == 1){ 
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
  
  int offscreenPoints(PVector point1, PVector point2){
    if (    (point1.x >= offscreenCanvasMargin && point1.x <= graphics.width-offscreenCanvasMargin && point1.y >= offscreenCanvasMargin && point1.y <= graphics.height-offscreenCanvasMargin)
         || (point2.x >= offscreenCanvasMargin && point2.x <= graphics.width-offscreenCanvasMargin && point2.y >= offscreenCanvasMargin && point2.y <= graphics.height-offscreenCanvasMargin) )  {
      // one or both of the two points are inside the margins
      
      if ((point1.x <= offscreenCanvasMargin && point2.x > offscreenCanvasMargin) || (point2.x <= graphics.width-offscreenCanvasMargin && point1.x > graphics.width-offscreenCanvasMargin)) return 0;
      if ((point2.x <= offscreenCanvasMargin && point1.x > offscreenCanvasMargin) || (point1.x <= graphics.width-offscreenCanvasMargin && point2.x > graphics.width-offscreenCanvasMargin)) return 1;
      if ((point1.y <= offscreenCanvasMargin && point2.y > offscreenCanvasMargin) || (point2.y <= graphics.height-offscreenCanvasMargin && point1.y > graphics.height-offscreenCanvasMargin)) return 0;
      if ((point2.y <= offscreenCanvasMargin && point1.y > offscreenCanvasMargin) || (point1.y <= graphics.height-offscreenCanvasMargin && point2.y > graphics.height-offscreenCanvasMargin)) return 1;
            
      return -1;
    } else {
      // both of the two points are inside the margins
      return 3;
    }
  }
  
  ArrayList<PVector> cropLine(PVector point1, PVector point2){
    ArrayList<PVector> result = new ArrayList<PVector>();
    
    result.add(point1);
    result.add(point2);
    
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
      
      if (x1<x2) result.set(0,new PVector(intersectionX,intersectionY));
      else result.set(1,new PVector(intersectionX,intersectionY));
      return result;
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
      
      if (x1<x2) result.set(1,new PVector(intersectionX,intersectionY));
      else result.set(0,new PVector(intersectionX,intersectionY));
      
      return result;
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
      
      if (y1<y2) result.set(0,new PVector(intersectionX,intersectionY));
      else result.set(1,new PVector(intersectionX,intersectionY));
      
      return result;
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
      
      if (y1<y2) result.set(1,new PVector(intersectionX,intersectionY));
      else result.set(0,new PVector(intersectionX,intersectionY));
      
      return result;
    }  
    
    // return uncropped points
    return result;
  }
}
