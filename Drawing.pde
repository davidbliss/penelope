// Project specific drawing things go here

// TODO: possible ideas for future:
  // sketch_210920_ga_linedrawing - draw lines and perterb them based on the current region they are within -- maybe levergaing some what is in the offest line code
  // sketch_210920_ga_linedrawing - connecting nearby points of similar brightness
  // python - advanced contour management

public class Drawing{
  Letters letters = new Letters();
  ArrayList<ContourLevel> levels;
  PApplet applet;
  int numContours;
  int firstLayer;
  
  Drawing(PApplet applet, int numContours, int firstLayer){
    this.applet = applet;
    this.numContours = numContours;
    this.firstLayer = firstLayer;
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
    //println("levels.size()",levels.size());
    if(levels != null){
      for (int i=0; i<this.numContours; i++){
        println("drawing level", i);
        
        RShape contours = levels.get(i).getContours();
        
        float imageWidth = loadedImage.width * parameters.cp5.getController("sampleScale").getValue();
        float imageHeight = loadedImage.height * parameters.cp5.getController("sampleScale").getValue();
        
        if (i < this.numContours-1) contours = RG.diff(contours, levels.get(i+1).getContours());
        
        // TODO: scale contours to fill the width or height
        float scaleX = (canvas.width-canvas.margin * 2) / imageWidth;
        float scaleY = (canvas.height-canvas.margin * 2) / imageWidth;
        float scale = scaleY;
        if (scaleX < scaleY) scale = scaleX;
        
        int offsetX = ( canvas.width - int(imageWidth * scale) ) / 2;
        int offsetY = ( canvas.height - int(imageHeight * scale) ) / 2;
        contours.scale(scale);
        contours.translate(offsetX, offsetY);
        
        RShape fill = geoUtils.fill(contours, 1+(levels.get(i).getThreshold()/10) , true);
      
        canvas.addShape(i+this.firstLayer, fill);
        canvas.addShape(i+this.firstLayer, contours);
      }
    }
    println("drawing done");
  }
  
  void processImage(){
    // TODO: change to variable number of thresholds rather than just the one
    levels = new ArrayList<ContourLevel>();
    for (int i=0; i<this.numContours; i++){
      ContourLevel level = new ContourLevel(applet, loadedImage.copy(), parameters.cp5.getController("sampleScale").getValue(), int(parameters.cp5.getController("threshold"+i).getValue()));
      
      float[] values = parameters.cp5.getController("contourSizeRange").getArrayValue();
      level.removeContoursSmallerThan(values[0]);
      level.removeContoursBiggerThan(values[1]);
      levels.add(level);
    }
    println("image processing complete");
  }
}
