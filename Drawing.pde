// Project specific drawing things go here

// TODO: possible ideas for future:
  // sketch_210920_ga_linedrawing - connecting nearby points of similar brightness
  // python - advanced contour management

public class Drawing{
  Letters letters = new Letters();
  ArrayList<ContourLevel> levels = new ArrayList<ContourLevel>();;
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
    println("levels.size()",levels.size());
    if(levels.size()>0){
      for (int i=0; i<this.numContours; i++){
        ArrayList<RShape> contours = levels.get(i).getContours();
        
        for (RShape contour: contours){
          canvas.addMaskedShape(i+this.firstLayer, contour);
        }
      }
    }
  }
  
  void processImage(){
    println("image loaded");
    for (int i=0; i<this.numContours; i++){
      ContourLevel level = new ContourLevel(applet, loadedImage.copy(), parameters.cp5.getController("sampleScale").getValue(), int(parameters.cp5.getController("threshold"+i).getValue()));
      
      float[] values = parameters.cp5.getController("contourSizeRange").getArrayValue();
      level.removeContoursSmallerThan(values[0]);
      level.removeContoursBiggerThan(values[1]);
      levels.add(level);
    }
    println("image processing complete");
    
    // TODO: calling right away crashes app
    //drawOnce();
  }
}
