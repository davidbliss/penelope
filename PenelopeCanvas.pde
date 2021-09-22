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
      drawPolyline(points);

      points = new ArrayList<PVector>();
      points.add(p72d);
      points.add(p32d);
      drawPolyline(points);
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
      drawPolyline(points);

      points = new ArrayList<PVector>();
      points.add(p12d);
      points.add(p52d);
      points.add(p72d);
      points.add(p32d);
      drawPolyline(points);

      points = new ArrayList<PVector>();
      points.add(p52d);
      points.add(p62d);
      points.add(p22d);
      drawPolyline(points);

      points = new ArrayList<PVector>();
      points.add(p62d);
      points.add(p82d);
      drawPolyline(points);
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

    drawPolyline(points, true);
  }

  // start line cropping utilities.
  
  void drawPolyline(ArrayList<PVector> points){
    drawPolyline(points, true);
  }
  
  void drawPolyline(ArrayList<PVector> points, boolean isStandalone){
    graphics.clip(margin, margin, graphics.width - 2*margin, graphics.height - 2*margin);
    if (isStandalone==true) graphics.beginShape();
    for (PVector point : points){
      graphics.vertex(point.x, point.y);
    }
    if (isStandalone==true) graphics.endShape();
  }

  // start signature
  void sign(){
    graphics.beginShape();
    graphics.noFill();

    int sigWidth=30;

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
