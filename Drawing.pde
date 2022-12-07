// For convinience, all drawing things are consolidated here

public class Drawing{
  Letters letters = new Letters();

  Drawing(){
  }

  public void draw(PenelopeCanvas canvas){
    // something filled
    RShape shape = new RShape();
    RPath path = new RPath(0,0);
    path.addLineTo(canvas.width, canvas.height);
    path.addLineTo(0, canvas.height);
    path.addLineTo(0,0);
    shape.addPath(path);
    println("draw: shape dimensions", shape.width, shape.height);
    
    RShape thisfills = geoUtils.iterativelyFill(shape, 1, false); 
   
    canvas.addShape(0, thisfills);
    canvas.addShape(0, shape);
    
 
    // something filled
    shape = new RShape();
    path = new RPath(canvas.width/3,canvas.height/3);
    path.addLineTo(canvas.width-canvas.width/3, canvas.height-canvas.height/3);
    path.addLineTo(canvas.width-canvas.width/3, canvas.height/3);
    path.addLineTo(canvas.width/3,canvas.height/3);
    shape.addPath(path);
    
    thisfills = geoUtils.iterativelyFill(shape, 10, true); 
   
    canvas.addShape(2, thisfills);
    canvas.addShape(2, shape);
    
    // something not filled
    RShape  border = RShape.createRectangle(canvas.margin, canvas.margin, canvas.width-(canvas.margin*2), canvas.height-(canvas.margin*2));
    canvas.addShape(1, border);
    
    // some words
    RShape words = letters.getWords("happy");
    words.scale(10);
    canvas.addShape(2, words);
  }
}
