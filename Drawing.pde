// Project specific drawing things go here

// TODO: possible ideas for future:
  // sketch_210920_ga_linedrawing - draw lines and perterb them based on the current region they are within -- maybe levergaing some what is in the offest line code
  // sketch_210920_ga_linedrawing - connecting nearby points of similar brightness
  // python - advanced contour management

public class Drawing{
  Letters letters = new Letters();
  ArrayList<ContourLevel> levels;
  PApplet applet;
  int canvasLayer;
  int firstLayer;
  
  Drawing(PApplet applet, int canvasLayer){
    this.applet = applet;
    this.canvasLayer = canvasLayer;
  }

  public void draw(PenelopeCanvas canvas){
    //// something filled
    //RShape shape = new RShape();
    //RPath path = new RPath(0,0);
    //path.addLineTo(canvas.width, canvas.height);
    //path.addLineTo(0, canvas.height);
    //path.addLineTo(0,0);
    //shape.addPath(path);
    
    //RShape thisfills = geoUtils.iterativelyFill(shape, 1, false); 
   
    //canvas.addShape(0, thisfills);
    //canvas.addShape(0, shape);
    
    //// something filled
    //shape = new RShape();
    //path = new RPath(canvas.width/3,canvas.height/3);
    //path.addLineTo(canvas.width-canvas.width/3, canvas.height-canvas.height/3);
    //path.addLineTo(canvas.width-canvas.width/3, canvas.height/3);
    //path.addLineTo(canvas.width/3,canvas.height/3);
    //shape.addPath(path);
    
    //thisfills = geoUtils.iterativelyFill(shape, 10, true); 
   
    //canvas.addShape(2, thisfills);
    //canvas.addShape(2, shape);
    
    //// something not filled
    //RShape  border = RShape.createRectangle(canvas.margin, canvas.margin, canvas.width-(canvas.margin*2), canvas.height-(canvas.margin*2));
    //canvas.addShape(1, border);
    
    // some words
    //RShape words = letters.getWords("happy");
    //words.scale(10);
    //canvas.addShape(2, words);
    
    // contours (requires image to be loaded)
    
    RShape circles = generateCircles(int(canvas.width/2), int(canvas.height/2), 200, 5);
    //canvas.addShape(1, circles);
    RShape circles2 = generateCircles(int(canvas.width/2)+100, int(canvas.height/2)+100, 200, 5);
    circles2.polygonize();
    //RShape circles3 = geoUtils.iterativelyClip(circles.createCircle(int(canvas.width/2), int(canvas.height/2), 400),  circles2);
    
    RShape circles3 = RG.diff(circles2, circles.createCircle(int(canvas.width/2), int(canvas.height/2), 400));
    
    RShape shape = new RShape();
    shape.addChild(circles.createCircle(int(canvas.width/2), int(canvas.height/2), 400));
    shape.addChild(circles.createCircle(int(canvas.width/2)+20, int(canvas.height/2), 400));
    shape.addChild(circles.createCircle(int(canvas.width/2)+100, int(canvas.height/2), 100));
    shape.addChild(circles.createCircle(int(canvas.width/2)-400, int(canvas.height/2), 100));
    shape.addChild(RG.getLine(0,0,canvas.width, canvas.height));
    
    RShape clipShape = circles.createCircle(int(canvas.width/2+100), int(canvas.height/2), 400);
    
    RShape newShape = clipShape(shape, clipShape);
    
    //canvas.addShape(1, shape);
    canvas.addShape(1, newShape);
    canvas.addShape(1, clipShape);
    
    
    //int numContours = int(parameters.cp5.getController("numContours").getValue());
    //if(levels != null){
    //  for (int i=0; i<numContours; i++){
    //    println("drawing level", i);
        
    //    RShape contours = levels.get(i).getContours();
        
    //    float imageWidth = loadedImage.width * parameters.cp5.getController("sampleScale").getValue();
    //    float imageHeight = loadedImage.height * parameters.cp5.getController("sampleScale").getValue();
        
    //    if (i < numContours-1) contours = RG.diff(contours, levels.get(i+1).getContours());
        
    //    float scaleX = (canvas.width-canvas.margin * 2) / imageWidth;
    //    float scaleY = (canvas.height-canvas.margin * 2) / imageWidth;
    //    float scale = scaleY;
    //    if (scaleX < scaleY) scale = scaleX;
        
    //    int offsetX = ( canvas.width - int(imageWidth * scale) ) / 2;
    //    int offsetY = ( canvas.height - int(imageHeight * scale) ) / 2;
    //    contours.scale(scale);
    //    contours.translate(offsetX, offsetY);
        
    //    if(parameters.cp5.getController("showFill").getValue()==1.0 && i < numContours - 1){
    //      float fillSpacing = (1+(levels.get(i).getThreshold()/10)) * parameters.cp5.getController("fillSpacing").getValue();
    //      RShape fill = geoUtils.fill(contours, fillSpacing, true);
    //      canvas.addShape(canvasLayer, fill);
    //    }
        
    //    if(parameters.cp5.getController("showContours").getValue()==1.0) canvas.addShape(canvasLayer, contours);
    //  }
    //  if(controls.cp5.getController("showImage").getValue()==1.0) image(levels.get(0).getAdjustedImage(), 0, 0);
    //}
    
    println("drawing done");
  }
  
  RShape clipShape(RShape shape, RShape clipShape){
    RShape newShape = new RShape();
    if(shape.countChildren() > 0){
      for(RShape child: shape.children){
        newShape.addChild( clipShape(child, clipShape) );
      }
    }
    if(shape.countPaths() > 0){
      for(RPath path: shape.paths){
        if(clipShape.contains(path) == true) {
          // if path is entirely inside, add it
          newShape.addChild(new RShape(path));
          println("path is entirely inside");
        } else if(clipShape.getIntersections(new RShape(path)) == null){
          // if path is entirely outside, ignore it
          println("path is entirely outside");
        } else {
          println("path is to be dealt with", shape.getPoints().length);
          
          RPath newPath = new RPath();
          ArrayList<ArrayList<RPoint>> pointsList = new ArrayList<ArrayList<RPoint>>();
          ArrayList<RPoint> points = new ArrayList<RPoint>();
          RPoint[] pathPoints = shape.getPoints();
          
          Boolean penDown = false;
          for(int i=0; i < shape.getPoints().length-1; i++) {
            if( clipShape.contains(pathPoints[i]) && clipShape.contains(pathPoints[i+1])) {
              // both points are inside
              if (penDown == false){
                points.add(pathPoints[i]);
                penDown = true;
              }
              points.add(pathPoints[i+1]);
            } else {
              RShape line = RG.getLine(pathPoints[i].x, pathPoints[i].y, pathPoints[i+1].x, pathPoints[i+1].y);
              RPoint[] intersection = line.getIntersections(clipShape);
              if (intersection == null) {
                //println("line has no intersections");
              } else if (intersection.length==1){
                //println("line has one intersection");
                if(clipShape.contains(pathPoints[i])){
                  points.add(pathPoints[i]);
                  points.add(intersection[0]);
                  penDown = false;
                } else {
                  points.add(intersection[0]);
                  points.add(pathPoints[i+1]);
                  penDown = true;
                }
              } else if (intersection.length>1){
                // TODO: this is more difficult could intersect many times, make a line from each and test if midpoint is in or out
                println("line has multiple intersections", intersection.length);
              } 
              
            }
          }
          // TODO: handle final point to first point
          
          pointsList.add(points);
          newShape.addChild(geoUtils.pointsToShape(pointsList));
        }
      }
    }
    return newShape;
  }
  
  void processImage(){
    // create contours
    levels = new ArrayList<ContourLevel>();
    for (int i=0; i < int(parameters.cp5.getController("numContours").getValue()); i++){
      int threshold = int(float(i)/int(parameters.cp5.getController("numContours").getValue())*100) - 1; 
      ContourLevel level = new ContourLevel(applet, loadedImage.copy(), parameters.cp5.getController("sampleScale").getValue(), threshold);
      
      float[] values = parameters.cp5.getController("contourSizeRange").getArrayValue();
      level.removeContoursSmallerThan(values[0]);
      level.removeContoursBiggerThan(values[1]);
      levels.add(level);
    }
    println("image processing complete");
  }
  
  RShape generateCircles(int x, int y, int r, float spacing) {
    RShape shape = new RShape();
    float currentRadius = spacing;
    while (currentRadius < r){
      shape.addChild(RShape.createCircle(float(x),float(y),currentRadius*2));
      currentRadius += spacing;
    }
    return shape;
  }
}
