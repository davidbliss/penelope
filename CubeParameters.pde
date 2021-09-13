import controlP5.*;

public class CubeParameters extends Parameters {
 
  CubeParameters(PApplet parent) {
    super(parent);
  }
  
  void customParameters(PVector pos){
    int xBase = int(pos.x);
    int yBase = int(pos.y);
    int xPos = xBase;
    int yPos = yBase;
    int yOffset = 25;
    int xOffset = 130;

    cp5.addSlider("numCols")
      .setLabel("number of columns")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(1,50)
      .setValue(5)
     ;
     
    xPos+=xOffset+50;

    cp5.addSlider("numRows")
      .setLabel("number of rows")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(1,50)
      .setValue(8)
     ;
    
    yPos+=yOffset;
    xPos=xBase;
    
    cp5.addSlider("offsetZ")
      .setLabel("Z shift")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(0,2)
      .setValue(1)
     ;
  }
}
