import controlP5.*;

public class Parameters {
  ControlP5 cp5;
  ParameterManager manager;

  Parameters(PApplet parent) {
    cp5 = new ControlP5(parent);

    manager= new ParameterManager(cp5);
    
    customParameters(new PVector(810, 10));
  }
  void customParameters(PVector pos){
    int xBase = int(pos.x);
    int yBase = int(pos.y);
    int xPos = xBase;
    int yPos = yBase;
    int yOffset = 25;
    int xOffset = 130;

    cp5.addSlider("fillDensity")
      .setLabel("fill density")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(1,10)
      .setValue(1)
     ;
    
    yPos+=yOffset;
    xPos=xBase;
  }
}
