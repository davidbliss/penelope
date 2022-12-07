// For convinience, all drawing things are consolidated here

public class Drawing{
  Parameters parameters;

  Drawing(Parameters parameters){
    this.parameters = parameters;
  }

  public void draw(PenelopeCanvas canvas){
    RShape  border = RShape.createRectangle(canvas.margin, canvas.margin, canvas.width-(canvas.margin*2), canvas.height-(canvas.margin*2));
    canvas.addShape(0, border);
  
    // TODO: add something basic here
    
    // TODO: do something with letters here
  }
}
