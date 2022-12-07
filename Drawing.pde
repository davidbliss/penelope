// For convinience, all drawing things are consolidated here

public class Drawing{
  Parameters parameters;
  Letters letters = new Letters();

  Drawing(Parameters parameters){
    this.parameters = parameters;
  }

  public void draw(PenelopeCanvas canvas){
    // something filled
    RShape shape = new RShape();
    RPath path = new RPath(0,0);
    path.addLineTo(canvas.width, canvas.height);
    path.addLineTo(0, canvas.height);
    path.addLineTo(0,0);
    shape.addPath(path);
    shape = geoUtils.hatchFill(shape, 1, false);
    canvas.addShape(0, shape);
    
    // TODO: FIRST: println not working?
    // TODO: manual fill of shape is not working.
    // something filled
    shape = new RShape();
    path = new RPath(canvas.width/3,canvas.height/3);
    path.addLineTo(canvas.width-canvas.width/3, canvas.height-canvas.height/3);
    path.addLineTo(canvas.width-canvas.width/3, canvas.height/3);
    path.addLineTo(canvas.width/3,canvas.height/3);
    shape.addPath(path);
    
    RShape thisfills = geoUtils.hatchFill(shape, 1, true); 
    
    thisfills = geoUtils.mergeLines(thisfills,1.25);
    if(thisfills.children!=null) {
      for (RShape child: thisfills.children) {
        child.setFill("none");
      }
    }
      
    canvas.addShape(2, thisfills);
    
    // something not filled
    RShape  border = RShape.createRectangle(canvas.margin, canvas.margin, canvas.width-(canvas.margin*2), canvas.height-(canvas.margin*2));
    canvas.addShape(1, border);
    
    // some words
    RShape words = letters.getWords("happy");
    words.scale(10);
    canvas.addShape(2, words);
  }
}
