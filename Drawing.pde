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
    RShape words = letters.getWords("happy");
    words.scale(10);
    canvas.addShape(2, words);
    
    // contours (requires image to be loaded)
    
    
    int numContours = int(parameters.cp5.getController("numContours").getValue());
    if(levels != null){
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
          float fillSpacing = (1+(levels.get(i).getThreshold()/10)) * parameters.cp5.getController("fillSpacing").getValue();
          RShape fill = geoUtils.fill(contours, fillSpacing, true);
          canvas.addShape(canvasLayer, fill);
        }
        
        if(parameters.cp5.getController("showContours").getValue()==1.0) canvas.addShape(canvasLayer, contours);
      }
    }
    println("drawing done");
  }
  
  void processImage(){
    levels = new ArrayList<ContourLevel>();
    for (int i=0; i < int(parameters.cp5.getController("numContours").getValue()); i++){
      
      int threshold = int(float(i)/int(parameters.cp5.getController("numContours").getValue())*100); 
      ContourLevel level = new ContourLevel(applet, loadedImage.copy(), parameters.cp5.getController("sampleScale").getValue(), threshold);
      
      float[] values = parameters.cp5.getController("contourSizeRange").getArrayValue();
      level.removeContoursSmallerThan(values[0]);
      level.removeContoursBiggerThan(values[1]);
      levels.add(level);
    }
    println("image processing complete");
  }
}
