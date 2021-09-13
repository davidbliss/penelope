// note, I tried to make this flexible enough to work for SVG and PDF,
// but ran into numerous errors that make me thing that if you want to use SVG or PDF,
// it does not make sense to do so in an offscreen canvas.

// TODO: BUG, PNG image is not being saved until it has been regenerated

public class PenelopeCanvas {
  PGraphics graphics;
  PGraphics offscreen3d;
  
  Parameters parameters; // drawing parameters that can be shuffled
  Controls controls;
  
  float scaleAdjust = 71.95;
  
  int margin;
  float camRotationX;
  float camRotationY;
  float camRotationZ;

  PenelopeCanvas(Parameters parameters, Controls controls) {
    this.parameters = parameters;
    this.controls = controls;
    int width = int(controls.cp5.getController("pageWidth").getValue()*scaleAdjust);
    int height = int(controls.cp5.getController("pageHeight").getValue()*scaleAdjust);
    init();
    
    graphics = createGraphics(width, height, P3D);
    offscreen3d = createGraphics(width, height, P3D);
  }

  PenelopeCanvas(PGraphics svg, Parameters parameters, Controls controls) {
    this.parameters = parameters;
    this.controls = controls;
    init();
    
    graphics = svg;
    offscreen3d = createGraphics(svg.width, svg.height, P3D);
  }
  
  void init(){
    // calculate the height and width of the offscreen bits.
    margin = int(controls.cp5.getController("margin").getValue()*scaleAdjust);
    
    camRotationX = parameters.cp5.getController("camRotationX").getValue();
    camRotationY = parameters.cp5.getController("camRotationY").getValue();
    camRotationZ = parameters.cp5.getController("camRotationZ").getValue();
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
    offscreen3d.translate(offscreen3d.width/2, offscreen3d.height/2, 0);
    offscreen3d.scale(parameters.cp5.getController("sceneScale").getValue());
    offscreen3d.rotateX(camRotationX);
    offscreen3d.rotateY(camRotationY);
    offscreen3d.rotateZ(camRotationZ);
  }

  void postDraw3d(){
    offscreen3d.popMatrix();
    offscreen3d.endDraw();
  }

  // start specialized functions for 2d objects
  void fillPolygon(){
    // TODO: take a list of pvertex and fill them with strokes
    // TODO: make a collectin of fill styles (dots, lines, solid).
  }

  // start functions for rendering 3d objects to 2d SVG.

  void drawBox(float size){
    drawBox(size, true);
  }
  
  void drawBox(float size, boolean isWireframe){
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

    PVector p12d = new PVector(offscreen3d.screenX(p1.x,p1.y,p1.z), offscreen3d.screenY(p1.x,p1.y,p1.z));
    PVector p22d = new PVector(offscreen3d.screenX(p2.x,p2.y,p2.z), offscreen3d.screenY(p2.x,p2.y,p2.z));
    PVector p32d = new PVector(offscreen3d.screenX(p3.x,p3.y,p3.z), offscreen3d.screenY(p3.x,p3.y,p3.z));
    PVector p42d = new PVector(offscreen3d.screenX(p4.x,p4.y,p4.z), offscreen3d.screenY(p4.x,p4.y,p4.z));
    PVector p52d = new PVector(offscreen3d.screenX(p5.x,p5.y,p5.z), offscreen3d.screenY(p5.x,p5.y,p5.z));
    PVector p62d = new PVector(offscreen3d.screenX(p6.x,p6.y,p6.z), offscreen3d.screenY(p6.x,p6.y,p6.z));
    PVector p72d = new PVector(offscreen3d.screenX(p7.x,p7.y,p7.z), offscreen3d.screenY(p7.x,p7.y,p7.z));
    PVector p82d = new PVector(offscreen3d.screenX(p8.x,p8.y,p8.z), offscreen3d.screenY(p8.x,p8.y,p8.z));

    if (isWireframe == false){
    // Front sides only
      ArrayList<PVector> points = new ArrayList<PVector>();
      points.add(p12d);
      points.add(p22d);
      points.add(p42d);
      points.add(p32d);
      points.add(p12d);
      points.add(p52d);
      points.add(p72d);
      points.add(p82d);
      points.add(p42d);
      drawCroppedPolyline(points);
  
      points = new ArrayList<PVector>();
      points.add(p72d);
      points.add(p32d);
      drawCroppedPolyline(points);
    } else {
      // all sides
      ArrayList<PVector> points = new ArrayList<PVector>();
      points.add(p42d);
      points.add(p22d);
      points.add(p12d);
      points.add(p32d);
      points.add(p42d);
      points.add(p82d);
      points.add(p72d);
      drawCroppedPolyline(points);
  
      points = new ArrayList<PVector>();
      points.add(p12d);
      points.add(p52d);
      points.add(p72d);
      points.add(p32d);
      drawCroppedPolyline(points);
  
      points = new ArrayList<PVector>();
      points.add(p52d);
      points.add(p62d);
      points.add(p22d);
      drawCroppedPolyline(points);
  
      points = new ArrayList<PVector>();
      points.add(p62d);
      points.add(p82d);
      drawCroppedPolyline(points);
    }
  }
  
  ArrayList<PVector> get3dBezierPoints(PVector anchor1, PVector control1, PVector control2, PVector anchor2){
    int steps = 2 + int(10 * controls.cp5.getController("curveFidelity").getValue()); // need minimum of 2 segments;

    ArrayList<PVector> points = new ArrayList<PVector>();

    for (int s = 0; s <= steps; s++) {
      float t = s / float(steps);

      float x = bezierPoint(anchor1.x, control1.x, control2.x, anchor2.x, t);
      float y = bezierPoint(anchor1.y, control1.y, control2.y, anchor2.y, t);
      float z = bezierPoint(anchor1.z, control1.z, control2.z, anchor2.z, t);

      float sX = offscreen3d.screenX(x,y,z);
      float sY = offscreen3d.screenY(x,y,z);

      points.add(new PVector(sX, sY));
    }

    return points;
  }

  void draw3dBezier(PVector anchor1, PVector control1, PVector control2, PVector anchor2){
    ArrayList<PVector> points = get3dBezierPoints(anchor1, control1, control2, anchor2);

    drawCroppedPolyline(points, true);
  }

  // start line cropping utilities.
  
  void drawCroppedPolylines(ArrayList<ArrayList<PVector>> lines){
    graphics.beginShape();
    for (ArrayList<PVector>points : lines){
      drawCroppedPolyline(points, false);
    }
    graphics.endShape();
  }
  
  void drawCroppedPolyline(ArrayList<PVector> points){
    drawCroppedPolyline(points, true);
  }

  void drawCroppedPolyline(ArrayList<PVector> points, boolean isStandalone){
    if (isStandalone==true) graphics.beginShape();
    float previousX = 0;
    float previousY = 0;

    Boolean newCurve = true;

    if(points.size()==2){
      // NOTE: when using a PGraphic, shapes with just two vertex don't get draw into the onscreen graphic (even though they do when using SVG).
      ArrayList<PVector> croppedLine = cropLine(points.get(0), points.get(1));
      if(croppedLine!=null) {
        graphics.vertex(croppedLine.get(0).x, croppedLine.get(0).y);
        graphics.vertex(croppedLine.get(1).x, croppedLine.get(1).y);
        graphics.vertex(croppedLine.get(1).x, croppedLine.get(1).y); // two work around the 2 vertex issue, send the second vertex twice.
      }
    } else {
      for (int p = 0; p < points.size(); p++){
        PVector point = points.get(p);
        float sX = point.x;
        float sY = point.y;
        if (newCurve == false){
          // skip duplicate vertexes
          if(sX != previousX || sY != previousY) {
            // See if crop is needed and to which side
            int offScreenPoints = offscreenPoints(new PVector(previousX, previousY), new PVector(sX, sY));
            ArrayList<PVector> croppedLine = cropLine(new PVector(previousX, previousY), new PVector(sX, sY));

            if (croppedLine!=null){
              // capture the first vertex if this is p is 1
              if(p==1) graphics.vertex(croppedLine.get(0).x, croppedLine.get(0).y);

              graphics.vertex(croppedLine.get(1).x, croppedLine.get(1).y);

              previousX = croppedLine.get(1).x;
              previousY = croppedLine.get(1).y;

              if (offScreenPoints == 2 || offScreenPoints == 3 ){
                // if you have only drawn 2 vertex before being cropped, they will not show up on screen without third, so duplicate last.
                if (p==1) graphics.vertex(previousX, previousY);
                
                graphics.endShape();
                if(isStandalone==false) graphics.beginShape();

                ArrayList<PVector> newPoints = new ArrayList<PVector>(points.subList(p, points.size()));
                drawCroppedPolyline(newPoints, isStandalone);
                break;
              }
            } else {
              // if you have only drawn 2 vertex before being cropped, they will not show up on screen without third, so duplicate last.
              if (p==1) graphics.vertex(previousX, previousY);
              
              graphics.endShape();
              if(isStandalone==false) graphics.beginShape();

              ArrayList<PVector> newPoints = new ArrayList<PVector>(points.subList(p, points.size()));
              drawCroppedPolyline(newPoints, isStandalone);
              break;
            }
          }

        } else {
          newCurve = false;
          previousX = sX;
          previousY = sY;
        }
      }
    }
    if (isStandalone==true) graphics.endShape();
  }

  void drawCroppedLine(PVector point1, PVector point2){
    ArrayList<PVector> croppedLine = cropLine(point1, point2);
    if (croppedLine!=null) graphics.line(croppedLine.get(0).x, croppedLine.get(0).y, croppedLine.get(1).x, croppedLine.get(1).y);
  }

  int offscreenPoints(PVector point1, PVector point2){
    if (    (point1.x >= margin && point1.x <= graphics.width-margin && point1.y >= margin && point1.y <= graphics.height-margin)
         && (point2.x >= margin && point2.x <= graphics.width-margin && point2.y >= margin && point2.y <= graphics.height-margin) )  {
      // both of the two points are inside the margins
      return 0;
    } else if (    (point1.x >= margin && point1.x <= graphics.width-margin && point1.y >= margin && point1.y <= graphics.height-margin)
         || (point2.x >= margin && point2.x <= graphics.width-margin && point2.y >= margin && point2.y <= graphics.height-margin) )  {
      // one or the other of the two points are inside the margins

      if ((point1.x <= margin && point2.x > margin) || (point2.x <= graphics.width-margin && point1.x > graphics.width-margin)) return 1;
      if ((point2.x <= margin && point1.x > margin) || (point1.x <= graphics.width-margin && point2.x > graphics.width-margin)) return 2;
      if ((point1.y <= margin && point2.y > margin) || (point2.y <= graphics.height-margin && point1.y > graphics.height-margin)) return 1;
      if ((point2.y <= margin && point1.y > margin) || (point1.y <= graphics.height-margin && point2.y > graphics.height-margin)) return 2;

      return -1;
    } else {
      // both of the two points are outside the margins
      return 3;
    }
  }

  // TODO: evolve this to crop line based on list of lines rather than 4 hardcoded boundaries. -- to be used for layering shapes
  ArrayList<PVector> cropLine(PVector point1, PVector point2){
    ArrayList<PVector> result = new ArrayList<PVector>();
    int numIntersections=0;
    // line 1
    float x1 = point1.x;
    float y1 = point1.y;
    float x2 = point2.x;
    float y2 = point2.y;

    // left side of paper 
    PVector intersection = intersectionOf2Lines(x1, y1, x2, y2, margin, margin, margin, graphics.height - margin);

    if (intersection!=null) {
      numIntersections++;
      if (x1<x2){
        x1 = intersection.x;
        y1 = intersection.y;
      } else {
        x2 = intersection.x;
        y2 = intersection.y;
      }
    }

    // right side of paper 
    intersection = intersectionOf2Lines(x1, y1, x2, y2, graphics.width - margin, margin, graphics.width - margin, graphics.height - margin);
    if (intersection!=null) {
      numIntersections++;
      if (x1<x2){
        x2 = intersection.x;
        y2 = intersection.y;
      } else {
        x1 = intersection.x;
        y1 = intersection.y;
      }
    }

    // top of paper
    intersection = intersectionOf2Lines(x1, y1, x2, y2, margin, margin, graphics.width - margin, margin);
    if (intersection!=null) {
      numIntersections++;
      if (y1<y2){
        x1 = intersection.x;
        y1 = intersection.y;
      } else {
        x2 = intersection.x;
        y2 = intersection.y;
      }
    }

    // bottom of paper 
    intersection = intersectionOf2Lines(x1, y1, x2, y2, margin, graphics.height - margin, graphics.width - margin, graphics.height - margin);
    if (intersection !=null){
      numIntersections++;
      if (y1<y2){
        x2 = intersection.x;
        y2 = intersection.y;
      } else {
        x1 = intersection.x;
        y1 = intersection.y;
      }
    }

    if (offscreenPoints(new PVector(x1,y1), new PVector(x2,y2)) == 3 && numIntersections == 0){
      return null;
    }

    // return uncropped points
    result.add(new PVector(x1,y1));
    result.add(new PVector(x2,y2));
    return result;
  }

  PVector intersectionOf2Lines(float x1, float y1, float x2, float y2, float x3, float y3, float x4, float y4){
    float uA = ((x4-x3)*(y1-y3) - (y4-y3)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1)); // distance along line 1 where it intersects line 2
    float uB = ((x2-x1)*(y1-y3) - (y2-y1)*(x1-x3)) / ((y4-y3)*(x2-x1) - (x4-x3)*(y2-y1));

    // if uA and uB are between 0-1, lines are colliding
    if (uA >= 0 && uA <= 1 && uB >= 0 && uB <= 1) {
      float intersectionX = x1 + (uA * (x2-x1));
      float intersectionY = y1 + (uA * (y2-y1));

      return new PVector(intersectionX, intersectionY);
    } else {
      return null;
    }
  }
  
  // start signature 
  void sign(){
    graphics.beginShape();
    graphics.noFill();
    
    float sigWidth = (graphics.width - 2*margin )/25;
    
    float w = sigWidth/3;
    float h = w*1.75;
    float k = w/4;
    float r = w/3;
    
    float x = graphics.width - margin - sigWidth;
    float y = graphics.height - margin - h;
   
    //l
    graphics.vertex(x,y-h);
    //vertex(x,y+w/2-r);
    addArcVertexes(x+r, y+w/2-r, r, PI,HALF_PI);
    x += r;
    
    //o
    addArcVertexes(x+w/2, y, w/2, HALF_PI, -3*HALF_PI);
    x += w+k;
    
    //p
    addArcVertexes(x+w/2, y, w/2, HALF_PI, -2*HALF_PI);
    graphics.vertex(x,y);
    graphics.vertex(x,y+h);
    
    graphics.endShape();
  }
  
  void addArcVertexes(float x, float y, float r, float start, float end){
    
    float arcLength = end - start;
    float segmentLength = QUARTER_PI/3;
    if(arcLength<0) segmentLength *= -1;
    int numSegments = abs(ceil(arcLength / segmentLength));
    
    for (int i = 0; i <= numSegments; i++){
       float thisX = x + r * cos(start+i*segmentLength);
       float thisY = y + r * sin(start+i*segmentLength);
       graphics.vertex(thisX, thisY);
    }
  }
}