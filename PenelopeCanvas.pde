import geomerative.*;
import java.util.ArrayList;

public class PenelopeCanvas {
  Controls controls;
  PGraphics graphics;
  
  int margin;
  int width;
  int height;  
  
  float fillDensity = 1;

  // based on the PenController software
  float scaleAdjust = 71.95f;
  
  // each layer is an RShape so that it can be differenced and saved to disk (RGroups, can't do either)
  // this may complicate things a bit since RPaths are used to create manually clipped lines
  int numLayers;
  ArrayList<RShape> layers;
  RShape boundaries;
  RShape circleBoundary;
  RPath leftPath;
  RPath rightPath;
  RPath topPath;
  RPath bottomPath;
  
  public PenelopeCanvas(PApplet applet, Controls controls, int numLayers) {
    this.controls = controls;
    this.numLayers = numLayers;
    
    RG.init(applet);
    RG.setPolygonizer(RG.ADAPTATIVE);

    initLayers();
  }
  
  // for good solid fill with 05 micron, use 1. 1.5 is also nice (good texture up close).... however, if you print things that are scaled up, 1 introduces errors... and reassl large scales 1.5 has trouble.
  public void setFillDensity(float fd) {
    fillDensity = fd;
  }
  
  public void initLayers(){
    layers = new ArrayList<RShape>();
    for (int i = 0; i<numLayers; i++){
      RShape layer = new RShape();
      layer.setStrokeWeight(1);
      layer.setFillAlpha(0);
      layer.setStroke(colorManager.colors[i]);
      layers.add(layer);
    }
  }
  
  public void clear(){
    initLayers();
  }
  
  public void clearGraphicsOnly(){
    graphics.beginDraw();
    graphics.background(255);
    graphics.endDraw();
  }
  
  public void setDimensions(){
    width = (int) (controls.cp5.getController("pageWidth").getValue()*scaleAdjust);
    height = (int) (controls.cp5.getController("pageHeight").getValue()*scaleAdjust);
    margin = (int) (controls.cp5.getController("margin").getValue()*scaleAdjust);

    graphics = createGraphics(width, height);
    
    boundaries = RShape.createRectangle(margin, margin, width-2*margin, height-2*margin);
    circleBoundary = RShape.createEllipse(width/2, height/2, width-2*margin, height-2*margin);
    
    leftPath = new RPath(new RCommand(margin, margin, margin, height - margin));
    rightPath = new RPath(new RCommand(width - margin, margin, width - margin, height - margin));
    topPath = new RPath(new RCommand(margin, margin, width - margin, margin));
    bottomPath = new RPath(new RCommand(margin, height - margin, width - margin, height - margin));
  }
  
  public void draw(){
    draw(false);
  }
  
  public void draw(boolean fill){
    println("PenelopeCanvas draw called, may take a while...");
    graphics.beginDraw();
    
    for (int l=0; l<layers.size(); l++){
      println("PenelopeCanvas drawing layer", l+1, "of",layers.size(), ". This may take a while...");
      //if (layer.getPoints()!=null) println("points",layer.getPoints().length);
      
      // TODO: this call is expensive, would be ideal to draw the preview directly to the canvas when 
      // "The tessellator is generating too many vertices"
      // should we have a canvas for each individual to reduce the redraws?
      draw(l, fill);
    }
    graphics.endDraw();
  }
  
  public void draw(int _layer){
    draw(_layer,false);
  }
  
  public void draw(int _layer, boolean fill){
    if(fill == true) {
      if (layers.get(_layer).children!=null) {
        for(RShape child: layers.get(_layer).children) {
          RShape filled = geoUtils.iterativelyFill(child, fillDensity, true);
          layers.get(_layer).addChild(filled);
        }
      } 
    }
    
    println("PenelopeCanvas draw called, may take a while...");
    graphics.beginDraw();
    
    println("PenelopeCanvas drawing a layer. This may take a while...");
    layers.get(_layer).draw(graphics);

    graphics.endDraw();
    println("PenelopeCanvas draw finished.");
  }
  
  public void saveImage(String output){
    String name = "output/"+month()+"."+day()+"."+year()+"_"+hour()+"-"+minute()+"-"+second();
    
    String[] lines = new String[1];
    lines[0] = output;
    saveStrings(name + ".txt", lines);
    
    // if you don't draw again, graphics is blank?
    draw();
    println("PenelopeCanvas saving PNG");
    PImage crop = graphics.get(0, 0, width, height);
    crop.save(name+".png");
    
    for (int l=0; l<layers.size(); l++){
      String svgName = name+"-layer-"+l+".svg";
      println("PenelopeCanvas saving SVG", l+1, "of",layers.size(), ". This may take a while...");
      RG.saveShape(svgName,layers.get(l));
      // hack to work around fact that geomerative does not save the width and height.
      String[] file = loadStrings(svgName);
      file[2]=file[2].replace("width=\"100%", "width=\""+width);
      file[2]=file[2].replace("height=\"100%", "height=\""+height);
      saveStrings(svgName, file);
    }
    println("PenelopeCanvas save finished.");
  }
  
  public void addShape(int layerNum, RShape shape){
    RShape layer = layers.get(layerNum);
    
    layer.addChild(shape);
  }
  
  public void addMaskedShape(int layerNum, ArrayList<PVector> points){
    RShape layer = layers.get(layerNum);
    RShape newShape = new RShape();
    RPath newLine = new RPath(points.get(0).x, points.get(0).y);
    
    for (int i=1; i<points.size(); i++){
      newLine.addLineTo(points.get(i).x, points.get(i).y);
    }
    // close shape;
    newLine.addLineTo(points.get(0).x, points.get(0).y);
    
    newShape.addPath(newLine);
    
    RShape layeredShape = new RShape();
    
    layeredShape = maskShape(layeredShape, newShape);
    layeredShape = clipShape(layeredShape, boundaries);
    layer.addChild(layeredShape);
  }
  
  public void addMaskedShape(int layerNum, RShape shape){
    RShape layer = layers.get(layerNum);
    
    RShape layeredShape = new RShape();
    
    layeredShape = maskShape(layer, shape);
    layeredShape = clipShape(layeredShape, boundaries);
    
    layers.set(layerNum, layeredShape);
  }
    
  // add a shape to another, and knock out any lines inside the new shape
  public RShape maskShape(RShape originalShape, RShape newShape){
    if(originalShape.countChildren()==0){
      originalShape.addChild(newShape);
    } else {
      originalShape = RG.diff(originalShape, newShape);
      originalShape.addChild(newShape);
    }
    return originalShape;
  }
    
  // use built in intersection to clip complex shapes
  public RShape clipShape(RShape originalShape, RShape clipShape){
    originalShape = RG.intersection( originalShape, clipShape);
    return originalShape;
  }
  
  
  public void addPath(int layerNum, ArrayList<RPoint> points){
    //println("addClippedPath, from points", layerNum, points.size());
    
    RPath path = new RPath(points.get(0).x, points.get(0).y);
    
    for (int p = 1; p < points.size(); p++){
      path.addLineTo(points.get(p).x, points.get(p).y);
    }
    
    RShape shape = new RShape();
      shape.addPath(path);
      if (path.getHandles() !=null && path.getHandles().length>0) layers.get(layerNum).addChild(shape);
  }
  
  // manual clipping
  // this is used to draw open lines that are clipped to the margin of the page
  // this is an option to useing Geomerative, which closes shapes to run intersection with margin. and is also quite a bit slower
  public ArrayList<ArrayList<RPoint>> clipPath(ArrayList<RPoint> points){
    //println("addClippedPath, from points", layerNum, points.size());
    
    ArrayList<ArrayList<RPoint>> output = new ArrayList<ArrayList<RPoint>>();
    ArrayList<RPoint> path = new ArrayList<RPoint>();
    
    for (int p = 1; p < points.size(); p++){
      // See if crop is needed and to which side
      int offScreenPoints = offscreenPoints(points.get(p-1), points.get(p));
      
      RPath segment = new RPath(new RCommand(points.get(p-1).x, points.get(p-1).y, points.get(p).x, points.get(p).y));
      
      RPath clippedSegment = clipPath(segment);
       
      if(clippedSegment!=null){
        if (path.size()==0) path.add(clippedSegment.getHandles()[0]);
        path.add(clippedSegment.getHandles()[1]);
        
        if (offScreenPoints == 2 || offScreenPoints == 3 ){
          if (path.size()>1) output.add(path);
          path = new ArrayList<RPoint>();
          processRemainingPoints(points, p);
          break;
        }
      } else {
        // null clippedSegment means that it was entirely out of bounds
         
        if (path.size()>1) output.add(path);
        path = new ArrayList<RPoint>();
        
        processRemainingPoints(points, p);
        break;
      }
    }
    if (path.size()>1) output.add(path);
    
    return output;
  }
  
  public ArrayList<ArrayList<RPoint>> clipPathCircle(ArrayList<RPoint> points){
    //println("addClippedPath, from points", layerNum, points.size());
    
    ArrayList<ArrayList<RPoint>> output = new ArrayList<ArrayList<RPoint>>();
    ArrayList<RPoint> path = new ArrayList<RPoint>();
    
    for (int p = 1; p < points.size(); p++){
      // See if crop is needed and to which side
      int offScreenPoints = offscreenPointsCircle(points.get(p-1), points.get(p));
      
      RPath segment = new RPath(new RCommand(points.get(p-1).x, points.get(p-1).y, points.get(p).x, points.get(p).y));
      
      RPath clippedSegment = clipPathCircle(segment);
       
      if(clippedSegment!=null){
        if (path.size()==0) path.add(clippedSegment.getHandles()[0]);
        path.add(clippedSegment.getHandles()[1]);
        
        
        if (offScreenPoints == 2 || offScreenPoints == 3 ){
          if (path.size()>1) output.add(path);
          path = new ArrayList<RPoint>();
        }
      } else {
        // null clippedSegment means that it was entirely out of bounds
         
        if (path.size()>1) output.add(path);
        path = new ArrayList<RPoint>();
      }
    }
    
    if (path.size()>1) output.add(path);
    return output;
  }
  
  public void processRemainingPoints(ArrayList<RPoint> points, int p){
    //println("processRemainingPoints", p, points.size());
    // we already tested the line between 0 and 1, no reason to continue if there are not more than 2 points in the list
    if(points.size()>1){
      // if a couple thousand of these points are out of range, you hit a stack overflow if you just recursively call the function, so we get rid of them all at once
      for(int p1 = p; p1<points.size()-1; p1++){
        RPoint point1 = points.get(p1);
        RPoint point2 = points.get(p1+1);
        if(point1.x >= margin && point1.x <= width-margin && point1.y >= margin && point1.y <= height-margin ||
         point2.x >= margin && point2.x <= width-margin && point2.y >= margin && point2.y <= height-margin){
          // confirm this works
          ArrayList<RPoint> newPoints = new ArrayList<RPoint>(points.subList(p1, points.size()));
          clipPath(newPoints);
          break;
        }
      }
    }
  }
  
  public void addClippedPath(int layerNum, ArrayList<RPoint> points){
    //println("addClippedPath, from points", layerNum, points.size());
    
    RPath path = null;
    
    for (int p = 1; p < points.size(); p++){
      // See if crop is needed and to which side
      int offScreenPoints = offscreenPoints(points.get(p-1), points.get(p));
      
      RPath segment = new RPath(new RCommand(points.get(p-1).x, points.get(p-1).y, points.get(p).x, points.get(p).y));
      
      RPath clippedSegment = clipPath(segment);
       
      if(clippedSegment!=null){
        if (path==null) path = new RPath(clippedSegment.getHandles()[0]);
        path.addLineTo(clippedSegment.getHandles()[1]);
        
        if (offScreenPoints == 2 || offScreenPoints == 3 ){
          //println("offscreen point, going to end this Path");
          
          //layers.get(layerNum).addPath(path);
          RShape shape = new RShape();
          shape.addPath(path);
          if (path.getHandles().length>0) layers.get(layerNum).addChild(shape);
          
          processRemainingPoints(points, p, layerNum);
          break;
        }
      } else {
        // null clippedSegment means that it was entirely out of bounds
         
        if (path !=null && path.getHandles().length>0) {
          // layers.get(layerNum).addPath(path);
          RShape shape = new RShape();
          shape.addPath(path);
          layers.get(layerNum).addChild(shape);
        }
        
        processRemainingPoints(points, p, layerNum);
        break;
      }
    }
    
    RShape shape = new RShape();
      shape.addPath(path);
      if (path !=null && path.getHandles().length>0) layers.get(layerNum).addChild(shape);
  }
  
  public void processRemainingPoints(ArrayList<RPoint> points, int p, int layerNum){
    //println("processRemainingPoints", p, points.size());
    // we already tested the line between 0 and 1, no reason to continue if there are not more than 2 points in the list
    if(points.size()>1){
      // if a couple thousand of these points are out of range, you hit a stack overflow if you just recursively call the function, so we get rid of them all at once
      for(int p1 = p; p1<points.size()-1; p1++){
        RPoint point1 = points.get(p1);
        RPoint point2 = points.get(p1+1);
        if(point1.x >= margin && point1.x <= width-margin && point1.y >= margin && point1.y <= height-margin ||
         point2.x >= margin && point2.x <= width-margin && point2.y >= margin && point2.y <= height-margin){
          // confirm this works
          ArrayList<RPoint> newPoints = new ArrayList<RPoint>(points.subList(p1, points.size()));
          addClippedPath(layerNum, newPoints);
          break;
        }
      }
    }
  }
  
  public int offscreenPoints(RPoint rPoint, RPoint rPoint2){
    if ((rPoint.x >= margin && rPoint.x <= width-margin && rPoint.y >= margin && rPoint.y <= height-margin)
     && (rPoint2.x >= margin && rPoint2.x <= width-margin && rPoint2.y >= margin && rPoint2.y <= height-margin) ){
      // both of the two points are inside the margins
      return 0;
    } else if ((rPoint.x >= margin && rPoint.x <= width-margin && rPoint.y >= margin && rPoint.y <= height-margin)
     || (rPoint2.x >= margin && rPoint2.x <= width-margin && rPoint2.y >= margin && rPoint2.y <= height-margin) ){
      // one or the other of the two points are inside the margins
      
      if ((rPoint.x <= margin && rPoint2.x > margin) || (rPoint2.x <= width-margin && rPoint.x > width-margin)) return 1;
      if ((rPoint2.x <= margin && rPoint.x > margin) || (rPoint.x <= width-margin && rPoint2.x > width-margin)) return 2;
      if ((rPoint.y <= margin && rPoint2.y > margin) || (rPoint2.y <= height-margin && rPoint.y > height-margin)) return 1;
      if ((rPoint2.y <= margin && rPoint.y > margin) || (rPoint.y <= height-margin && rPoint2.y > height-margin)) return 2;
      
      return -1;
    } else {
      // both of the two points are outside the margins
      return 3;
    }
  }
  
  public int offscreenPointsCircle(RPoint rPoint, RPoint rPoint2){
    if (circleBoundary.contains(rPoint)==true && circleBoundary.contains(rPoint2)==true ){
      // both of the two points are inside the margins
      return 0;
    } else if (circleBoundary.contains(rPoint)==false){
      return 1;
    } else if (circleBoundary.contains(rPoint2)==false) {
      return 2;
    } else {
      // both of the two points are outside the margins
      return 3;
    }
  }
  
  public RPath clipPathCircle(RPath originalPath){
    RPoint[] handles = originalPath.getHandles();
    // determine if path is outside of bounds entirely
    if (circleBoundary.contains(handles[0])==false && circleBoundary.contains(handles[1])==false ) {
//      println("line is outside of bounds");
      return null;
    }
    
    RPoint[] intersections = null;
    
    // for some reason intersectionPoints does not work circle path, so instead test each pair of points, one at a time. 
    for (int i = 0; i < circleBoundary.paths[0].getPoints().length; i++) {
      RPoint point = circleBoundary.paths[0].getPoints()[i];
      int ni = i+1;
      if(ni>=circleBoundary.paths[0].getPoints().length)ni=0;
      
      RPath pathToCheck = new RPath(point);
      pathToCheck.addLineTo(circleBoundary.paths[0].getPoints()[ni]);
      intersections = originalPath.intersectionPoints(pathToCheck);
      if (intersections!=null) break;
    }

//    println("intersections",intersections);
//    println("intersections.length",intersections.length);
    
    if (intersections!=null && intersections.length==1){
      if(circleBoundary.contains(handles[0])==false){
        originalPath = new RPath(new RCommand(intersections[0], handles[1]));
//        addShape(0,RShape.createCircle(handles[1].x, handles[1].y, 10));
//        addShape(0,RShape.createCircle(intersections[0].x, intersections[0].y, 10));
      } else if (circleBoundary.contains(handles[0])==true){
        originalPath = new RPath(new RCommand(handles[0], intersections[0]));
//        addShape(0,RShape.createCircle(handles[0].x, handles[0].y, 10));
//        addShape(0,RShape.createCircle(intersections[0].x, intersections[0].y, 10));
      } else {
        println("ERROR: can't determine how to crop");
      }
    } else if (intersections !=null && intersections.length>1){
      println("ERROR: somehow there was more than one left intersection");
    }
    
    return originalPath;
  }
  
  public RPath clipPath(RPath originalPath){
    // determine if path is outside of bounds entirely
    if(! boundaries.intersects(originalPath)) {
      //println("line is outside of bounds");
      return null;
    }
    
    RPoint[] intersections = originalPath.intersectionPoints(leftPath);
    if (intersections !=null && intersections.length==1){
      RPoint[] handles = originalPath.getHandles();
      if(handles[0].x<margin){
        originalPath = new RPath(new RCommand(intersections[0], handles[1]));
      } else if (handles[1].x<margin){
        originalPath = new RPath(new RCommand(handles[0], intersections[0]));
      } else {
        //println("ERROR: can't determine how to crop left");
      }
    } else if (intersections !=null && intersections.length>1){
      println("ERROR: somehow there was more than one left intersection");
    }
    
    intersections = originalPath.intersectionPoints(topPath);
    if (intersections !=null && intersections.length==1){
      RPoint[] handles = originalPath.getHandles();
      if(handles[0].y<margin){
        originalPath = new RPath(new RCommand(intersections[0], handles[1]));
      } else if (handles[1].y<margin){
        originalPath = new RPath(new RCommand(handles[0], intersections[0]));
      } else {
        //println("ERROR: can't determine how to crop top");
      }
    } else if (intersections !=null && intersections.length>1){
      println("ERROR: somehow there was more than one top intersection");
    }
    
    intersections = originalPath.intersectionPoints(rightPath);
    if (intersections !=null && intersections.length==1){
      RPoint[] handles = originalPath.getHandles();
      if(handles[0].x > width-margin){
        originalPath = new RPath(new RCommand(intersections[0], handles[1]));
      } else if (handles[1].x > width-margin){
        originalPath = new RPath(new RCommand(handles[0], intersections[0]));
      } else {
        //println("ERROR: can't determine how to crop right");
      }
    } else if (intersections !=null && intersections.length>1){
      println("ERROR: somehow there was more than one right intersection");
    }
    
    intersections = originalPath.intersectionPoints(bottomPath);
    if (intersections !=null && intersections.length==1){
      RPoint[] handles = originalPath.getHandles();
      if(handles[0].y > height-margin){
        originalPath = new RPath(new RCommand(intersections[0], handles[1]));
      } else if (handles[1].y > height-margin){
        originalPath = new RPath(new RCommand(handles[0], intersections[0]));
      } else {
        //println("ERROR: can't determine how to crop bottom");
      }
    } else if (intersections !=null && intersections.length>1){
      println("ERROR: somehow there was more than one bottom intersection");
    }
    
    return originalPath;
  }
  
  // start signature
  public void sign(int layerNum){
    int sigWidth=50;
    
    float w = sigWidth/5;
    float h = w*1.75f;
    float k = w/4;
    float r = w/3;
    
    float x = width - margin - sigWidth;
    float y = height - margin - h;
    
    RShape lopShape = new RShape();
    RPath lop = new RPath(x,y-h);
    
    //l
    lop = addArcTo(lop, x+r, y+w/2-r, r, PI, HALF_PI);
    x += r;
    
    //o
    lop = addArcTo(lop, x+w/2, y, w/2, HALF_PI, -3 * HALF_PI);
    x += w+k;
    
    //p
    lop = addArcTo(lop, x+w/2, y, w/2, HALF_PI, -2 * HALF_PI);
    lop.addLineTo(x,y);
    lop.addLineTo(x,y+h);
    
    lopShape.addPath(lop);
    
    x += w+k;
    
    RShape gaShape = new RShape();
    RPath ga = new RPath(x,y+h-w/2);
    
    //g
    ga = addArcTo(ga, x+w/2, y+h-w/2, w/2, PI, 0);
    ga.addLineTo(x+w,y);
    ga = addArcTo(ga, x+w/2, y, w/2, 0, -3 * HALF_PI);
    x += w+k;
    
    //a
    ga.addLineTo(x+w,y+w/2);
    ga.addLineTo(x+w,y);
    ga = addArcTo(ga, x+w/2, y, w/2, 0, -3 * HALF_PI);
    ga.addLineTo(x+w,y+w/2);
    
    gaShape.addPath(ga);
    
    // NOTE: adding each stroke to it's own shape before adding them to layer keeps paths from being closed automatically
    layers.get(layerNum).addChild(lopShape);
    layers.get(layerNum).addChild(gaShape);
  }

  RPath addArcTo(RPath path, float x, float y, float r, float start, float end){
    float arcLength = end - start;
    float segmentLength = QUARTER_PI/3;
    if(arcLength<0) segmentLength *= -1;
    int numSegments = abs(ceil(arcLength / segmentLength));
    for (int i = 0; i <= numSegments; i++){
      float thisX = x + r * cos(start+i*segmentLength);
      float thisY = y + r * sin(start+i*segmentLength);
      path.addLineTo(thisX, thisY);
    }
    return path;
  }
}
