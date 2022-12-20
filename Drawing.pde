// Project specific drawing things go here

// TODO: possible ideas for future:
  // make a text generating script separately and add ability to load SVG into canvas
  // sketch_210920_ga_linedrawing - draw lines and perterb them based on the current region they are within -- maybe levergaing some what is in the offest line code
  // sketch_210920_ga_linedrawing - connecting nearby points of similar brightness

ArrayList<RPoint> centers = new ArrayList<RPoint>(); 

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
    processImage();
    
    RShape message = RG.getText("Happy New Year!", "Phosphate-Solid.ttf", 44, LEFT);
    message.polygonize();
    message.scale(1,1.25);
    float paddedWidth = message.getWidth() + 2;
    
    float mLower = canvas.height - canvas.margin - canvas.height * .06;
    float mUpper = mLower - canvas.height * .20;
    
    float mRight = canvas.width * .96;
    float mLeft = mRight - paddedWidth;
    
    RShape curve = new RShape();
    curve.addMoveTo(mLeft, mLower);
    curve.addBezierTo(mLeft+message.getWidth()*.25, mLower, mRight-message.getWidth()*.25, mUpper, mRight, mUpper);
    
    message.translate(mLeft,0);
    for (RPoint point: message.getPoints()){
      point.translate(0, getYonCurve(curve, point.x));
    }
    
    canvas.addShape(2,message);
    
    if(levels != null){
      int numContours = int(parameters.cp5.getController("numContours").getValue());

      RShape allContours = new RShape();
      
      float imageWidth = loadedImage.width * parameters.cp5.getController("sampleScale").getValue();
      float imageHeight = loadedImage.height * parameters.cp5.getController("sampleScale").getValue();
      
      float scaleX = (canvas.width-canvas.margin * 2) / imageWidth;
      float scaleY = (canvas.height-canvas.margin * 2) / imageHeight;
      float scale = scaleY;
      if (scaleX < scaleY) scale = scaleX;
      
      int offsetX = ( canvas.width - int(imageWidth * scale) ) / 2;
      int offsetY = ( canvas.height - int(imageHeight * scale) ) / 2;
    
      for (int i=0; i<numContours; i++){
        println("drawing level", i);
        
        RShape contours = levels.get(i).getContours();
        
        RShape diffedContours = null;
        if (i < numContours-1) {
          // diffing before scaling is much quicker.
          diffedContours = RG.diff(contours, levels.get(i+1).getContours());
          diffedContours.scale(scale);
          diffedContours.translate(offsetX, offsetY);
        }
        
        contours.scale(scale);
        contours.translate(offsetX, offsetY);
        
        // add contours to allCountours before diffing them
        allContours.addChild(new RShape(contours));
        
        // show contours
        if(parameters.cp5.getController("showContours").getValue()==1.0) {
          contours = geoUtils.clipShape(contours, message, false);
          canvas.addShape(canvasLayer, contours);
        }
        
        // fill contours (except the lightest one)
        if(parameters.cp5.getController("showFill").getValue()==1.0 && i < numContours - 1){
          float fillSpacing = map(i * (1.0/(numContours-1)), 0.0, 1.0, int(parameters.cp5.getController("minFillSpacing").getValue()),int(parameters.cp5.getController("maxFillSpacing").getValue())); 
          RShape fill;
          if(centers.size()==0){
            fill = generateCircles(canvas.width/2, canvas.height/2, canvas.height, fillSpacing);
          } else {
            fill = new RShape();
            for(int j=0; j<centers.size(); j++){
              fill.addChild(generateCircles(int(centers.get(j).x), int(centers.get(j).y), canvas.height, fillSpacing));
            }
          }
          if (diffedContours!=null) {
            RShape clippedFill = geoUtils.clipShape(fill, diffedContours);
            
            clippedFill = geoUtils.clipShape(clippedFill, message, false);
            clippedFill = geoUtils.mergeLines(clippedFill, 1.75);
            clippedFill = geoUtils.filterShortLines(clippedFill, 2);
            
            canvas.addShape(canvasLayer, clippedFill);
          }
        }
      }
      
      
      println("processing key lines");
      // key lines (using all contour layers
      if(parameters.cp5.getController("showKeyLines").getValue()==1.0){
        float matchDistance = parameters.cp5.getController("matchDistance").getValue();
        float removeDistance = parameters.cp5.getController("removeDistance").getValue();
        removeDistance = min(removeDistance, matchDistance);
        
        float jaggedDistance = parameters.cp5.getController("jaggedDistance").getValue();
        float minLineLength = parameters.cp5.getController("minLineLength").getValue();
        float mergeDistance = parameters.cp5.getController("mergeDistance").getValue();
        float minArea = parameters.cp5.getController("minArea").getValue();
        
        RShape keyContours = geoUtils.findKeyContours(allContours, matchDistance, removeDistance); // ~9 and ~1-4 are good numbers for 20 contours and image scaled to 800 pixels
        keyContours = geoUtils.filterJaggedLines(keyContours, jaggedDistance);
        keyContours = geoUtils.filterShortLines(keyContours, minLineLength);
        keyContours = geoUtils.mergeLines(keyContours, mergeDistance);
        keyContours = geoUtils.filterSmallArea(keyContours, minArea); 
        
        keyContours = geoUtils.clipShape(keyContours, message, false);
        canvas.addShape(canvasLayer, keyContours);
      }
      
      
      if(controls.cp5.getController("showImage").getValue()==1.0) {
        image(levels.get(0).getAdjustedImage(), 0, 0);
        for (int i=0; i<numContours; i++){
          PGraphics sourceImage = createGraphics(levels.get(i).getThresholdImage().width,levels.get(i).getThresholdImage().height);
          sourceImage.beginDraw();
          sourceImage.noStroke();
          //sourceImage.fill(i*(1.0/numContours*255));
          sourceImage.fill(random(255),random(255),random(255));
          sourceImage.rect(0,0,sourceImage.width,sourceImage.height);
          sourceImage.endDraw();
          
          sourceImage.mask(levels.get(i).getThresholdImage());
          
          image(sourceImage, sourceImage.width,0);
        }
      }
    }
  }
  
  void processImage(){
    // create contours
    if(loadedImage!=null){
      levels = new ArrayList<ContourLevel>();
      int numContours = int(parameters.cp5.getController("numContours").getValue());
      for (int i=0; i < numContours; i++){
        float threshold = i*(1.0/numContours*100); 
        threshold = map(threshold, 0, 100, parameters.cp5.getController("minContourBrightness").getValue(), parameters.cp5.getController("maxContourBrightness").getValue());
        threshold = map(threshold, 0, 1, 0, 255);
        
        if(i==0) threshold = -1; // always make the first layer -1 to include black otherwise it drops out and fills are wrong
        
        ContourLevel level = new ContourLevel(applet, loadedImage.copy(), parameters.cp5.getController("sampleScale").getValue(), int(threshold));
        
        level.simplifyCountours(parameters.cp5.getController("contourSmoothingFactor").getValue());
        
        level.removeContoursSmallerThan(parameters.cp5.getController("minContourArea").getValue());
        level.removeContoursBiggerThan(parameters.cp5.getController("maxContourArea").getValue());
        levels.add(level);
      }
      println("image processing complete");
    }
  }
  
  float getYonCurve(RShape curve, float x){
    RShape line = RG.getLine(x, 0, x, canvas.height);
    RPoint[] intersections = curve.getIntersections(line);
    if (intersections != null && intersections.length > 0){
      return intersections[0].y;
    } else {
      return 0;
    }
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
