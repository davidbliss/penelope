public class PenelopeCanvas {
  PGraphics graphics;
  
  int margin;
  int width;
  int height;  

  // based on the PenController software
  float scaleAdjust = 71.95f;
  
  // each layer is an RShape so that it can be differenced and saved to disk (RGroups, can't do either)
  // this may complicate things a bit since RPaths are used to create manually clipped lines
  int numLayers;
  ArrayList<RShape> layers;
  RShape boundaries;
  RPath leftPath;
  RPath rightPath;
  RPath topPath;
  RPath bottomPath;
  
  public PenelopeCanvas(PApplet applet, int numLayers) {
    this.numLayers = numLayers;
    
    RG.init(applet);
    RG.setPolygonizer(RG.ADAPTATIVE);

    initLayers();
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
    
    leftPath = new RPath(new RCommand(margin, margin, margin, height - margin));
    rightPath = new RPath(new RCommand(width - margin, margin, width - margin, height - margin));
    topPath = new RPath(new RCommand(margin, margin, width - margin, margin));
    bottomPath = new RPath(new RCommand(margin, height - margin, width - margin, height - margin));
  }
  
  public void draw(){
    graphics.beginDraw();
    for (int l=0; l<layers.size(); l++){
      println("PenelopeCanvas drawing layer", l+1, "of",layers.size());
      draw(l);
    }
    graphics.endDraw();
  }
  
  public void draw(int _layer){
    println("PenelopeCanvas draw called, may take a while...");
    graphics.beginDraw();
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
  
  // add RShape to a given layer of canvas
  public void addShape(int layerNum, RShape shape){
    RShape layer = layers.get(layerNum);
    
    layer.addChild(shape);
  }
  
  // add am RShape to the canvas, masking exhisting content and clipping new content
  public void addMaskedShape(int layerNum, RShape shape){
    RShape layer = layers.get(layerNum);
    
    RShape layeredShape = new RShape();
    
    layeredShape = geoUtils.maskShapeFast(layer, shape);
    layeredShape = geoUtils.clipShapeFast(layeredShape, boundaries);
    
    layers.set(layerNum, layeredShape);
  }
  
  
  
  // add an ArrayList of points to the canvas without clipping them to margin
  public void addPath(int layerNum, ArrayList<RPoint> points){
    RPath path = new RPath(points.get(0).x, points.get(0).y);
    
    for (int p = 1; p < points.size(); p++){
      path.addLineTo(points.get(p).x, points.get(p).y);
    }
    
    RShape shape = new RShape();
      shape.addPath(path);
      if (path.getHandles() !=null && path.getHandles().length>0) layers.get(layerNum).addChild(shape);
  }
  
  // add an ArrayList of PVectors to the canvas, masking exhisting content and clipping new content
  public void addMaskedPath(int layerNum, ArrayList<PVector> points){
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
    
    layeredShape = geoUtils.maskShapeFast(layeredShape, newShape);
    layeredShape = geoUtils.clipShapeFast(layeredShape, boundaries);
    layer.addChild(layeredShape);
  }
  
  // add an ArrayList of points to the canvas after clipping it to the margin
  public void addClippedPath(int layerNum, ArrayList<RPoint> points){
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
  
  // add an ArrayList of points to the canvas after clipping it with the margin
  // used to draw open lines that are clipped to the margin of the page
  // this is an option to useing Geomerative, which closes shapes to run intersection with margin. and is also quite a bit slower
  public ArrayList<ArrayList<RPoint>> clipPath(ArrayList<RPoint> points){
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
  
  // used in clipPath
  private void processRemainingPoints(ArrayList<RPoint> points, int p){
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
  
  // used in addClippedPath
  private void processRemainingPoints(ArrayList<RPoint> points, int p, int layerNum){
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
  
  // clip RPath using the canvas margin
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
}
