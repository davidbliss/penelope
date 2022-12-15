// Project specific drawing things go here

// TODO: possible ideas for future:
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
    if(levels != null){
      int numContours = int(parameters.cp5.getController("numContours").getValue());
      
      
      RShape allContours = new RShape();
    
      for (int i=0; i<numContours; i++){
        println("drawing level", i);
        
        RShape contours = levels.get(i).getContours();
        
        float imageWidth = loadedImage.width * parameters.cp5.getController("sampleScale").getValue();
        float imageHeight = loadedImage.height * parameters.cp5.getController("sampleScale").getValue();
        
        float scaleX = (canvas.width-canvas.margin * 2) / imageWidth;
        float scaleY = (canvas.height-canvas.margin * 2) / imageWidth;
        float scale = scaleY;
        if (scaleX < scaleY) scale = scaleX;
        
        int offsetX = ( canvas.width - int(imageWidth * scale) ) / 2;
        int offsetY = ( canvas.height - int(imageHeight * scale) ) / 2;
        
        RShape diffedContours = null;
        if (i < numContours-1) {
          // diffing before scaling is much quicker. TODO: what about filling before scaling?
          println("about to diff");
          diffedContours = RG.diff(contours, levels.get(i+1).getContours());
          diffedContours.scale(scale);
          diffedContours.translate(offsetX, offsetY);
        }
        
        contours.scale(scale);
        contours.translate(offsetX, offsetY);
        
        // add contours to allCountours before diffing them
        println("about to add to all contours");
        allContours.addChild(new RShape(contours));
        
        // show contours
        if(parameters.cp5.getController("showContours").getValue()==1.0) canvas.addShape(canvasLayer, contours);
        
        // fill contours (except the lightest one)
        if(parameters.cp5.getController("showFill").getValue()==1.0 && i < numContours - 1){
        
          float fillSpacing = 1 + i * (1.0/(numContours-1)) * 3 * parameters.cp5.getController("fillSpacing").getValue(); 
          println("about to fill",fillSpacing, canvas.height);
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
        
        canvas.addShape(canvasLayer, keyContours);
      }
      
      
      if(controls.cp5.getController("showImage").getValue()==1.0) {
        image(levels.get(0).getAdjustedImage(), 0, 0);
        for (int i=0; i<numContours; i++){
          PGraphics sourceImage = createGraphics(levels.get(i).getThresholdImage().width,levels.get(i).getThresholdImage().height);
          sourceImage.beginDraw();
          sourceImage.noStroke();
          sourceImage.fill(i*(1.0/numContours*255));
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
        threshold = map(threshold, 0, 100, parameters.cp5.getController("contourBrightnessRange").getArrayValue()[0], parameters.cp5.getController("contourBrightnessRange").getArrayValue()[1]);
        threshold = map(threshold, 0, 1, -1, 255);
        ContourLevel level = new ContourLevel(applet, loadedImage.copy(), parameters.cp5.getController("sampleScale").getValue(), int(threshold));
        
        level.simplifyCountours(parameters.cp5.getController("contourSmoothingFactor").getValue());
        
        float[] values = parameters.cp5.getController("contourSizeRange").getArrayValue();
        level.removeContoursSmallerThan(values[0]);
        level.removeContoursBiggerThan(values[1]);
        levels.add(level);
      }
      println("image processing complete");
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
