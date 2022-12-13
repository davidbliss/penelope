// Project specific drawing things go here

// TODO: possible ideas for future:
  // sketch_210920_ga_linedrawing - draw lines and perterb them based on the current region they are within -- maybe levergaing some what is in the offest line code
  // sketch_210920_ga_linedrawing - connecting nearby points of similar brightness
  // create keycontours example

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
    
      for (int i=0; i<numContours; i++){
        println("drawing level", i);
        
        RShape contours = levels.get(i).getContours();
        
        float imageWidth = loadedImage.width * parameters.cp5.getController("sampleScale").getValue();
        float imageHeight = loadedImage.height * parameters.cp5.getController("sampleScale").getValue();
        
        if (i < numContours-1) contours = RG.diff(contours, levels.get(i+1).getContours());
        
        float scaleX = (canvas.width-canvas.margin * 2) / imageWidth;
        float scaleY = (canvas.height-canvas.margin * 2) / imageWidth;
        float scale = scaleY;
        if (scaleX < scaleY) scale = scaleX;
        
        int offsetX = ( canvas.width - int(imageWidth * scale) ) / 2;
        int offsetY = ( canvas.height - int(imageHeight * scale) ) / 2;
        contours.scale(scale);
        contours.translate(offsetX, offsetY);
        
        if(parameters.cp5.getController("showFill").getValue()==1.0 && i < numContours - 1){
          float fillSpacing = (1+i*((1.0/(numContours-1))*10))* parameters.cp5.getController("fillSpacing").getValue(); 
          RShape fill;
          if(centers.size()==0){
            fill = generateCircles(canvas.width/2, canvas.height/2, canvas.height, fillSpacing);
          } else {
            fill = new RShape();
            for(int j=0; j<centers.size(); j++){
              fill.addChild(generateCircles(int(centers.get(j).x), int(centers.get(j).y), canvas.height, fillSpacing));
            }
          }
          RShape clippedFill = geoUtils.clipShape(fill, contours);
          canvas.addShape(canvasLayer, clippedFill);
        }
        
        if(parameters.cp5.getController("showContours").getValue()==1.0) canvas.addShape(canvasLayer, contours);
      }
      
      if(controls.cp5.getController("showImage").getValue()==1.0) {
        image(levels.get(0).getAdjustedImage(), 0, 0);
        //for (int i=0; i<numContours; i++){
        //  image(levels.get(i).getThresholdImage(), 0+100*(i+1),0);
        //}
      }
    }
  }
  
  void processImage(){
    // create contours
    if(loadedImage!=null){
      levels = new ArrayList<ContourLevel>();
      int numContours = int(parameters.cp5.getController("numContours").getValue());
      for (int i=0; i < numContours; i++){
        float threshold = i*((1.0/(numContours-1))*100); 
        threshold = map(threshold, 0, 100, parameters.cp5.getController("contourBrightnessRange").getArrayValue()[0], parameters.cp5.getController("contourBrightnessRange").getArrayValue()[1]);
        threshold = map(threshold, 0, 1, -1, 255);
        ContourLevel level = new ContourLevel(applet, loadedImage.copy(), parameters.cp5.getController("sampleScale").getValue(), int(threshold));
        
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
