import controlP5.*;

public class Parameters {
  ControlP5 cp5;
  ParameterManager manager;

  Parameters(PApplet parent) {
    cp5 = new ControlP5(parent);

    manager= new ParameterManager(cp5);
    PVector pos = requiredParameters();
    
    customParameters(pos);
  }
  void customParameters(PVector pos){
    int xBase = int(pos.x);
    int yBase = int(pos.y);
    int xPos = xBase;
    int yPos = yBase;
    int yOffset = 25;
    int xOffset = 130;

    cp5.addSlider("numCellsX")
      .setLabel("cells in X")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(1,64)
      .setValue(32)
      ;
    xPos+=xOffset+50;

    cp5.addSlider("numCellsY")
      .setLabel("cells in Y")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(1,64)
      .setValue(32)
      ;
    xPos+=xOffset+50;

    cp5.addSlider("numCellsZ")
      .setLabel("cells in Z")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(1,64)
      .setValue(32)
      ;
    xPos+=xOffset+50;

    yPos+=yOffset;
    xPos=xBase;

    cp5.addSlider("numberChains")
      .setLabel("number of chains")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(1,300)
      .setValue(100)
      ;
    xPos+=xOffset+50;

    cp5.addSlider("lengthChains")
      .setLabel("length of chains")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(3,300)
      .setValue(200)
     ;

     xPos+=xOffset+50;

   cp5.addSlider("tightness")
     .setLabel("tightness")
     .setPosition(xPos, yPos)
     .setWidth(100)
     .setRange(0,1)
     .setValue(.35)
    ;

    yPos+=yOffset;
    xPos=xBase;

    cp5.addSlider("cellSize")
     .setLabel("cell size")
     .setPosition(xPos, yPos)
     .setWidth(100)
     .setRange(5,500)
     .setValue(100)
     ;
    xPos+=xOffset+50;

    xPos=xBase;
    yPos+=yOffset;

    cp5.addToggle("singleOccupancy")
    .setLabel("single occupancy")
    .setPosition(xPos, yPos)
    .setSize(50,10)
    .setValue(true)
    ;
  }
  
  PVector requiredParameters(){
    int xBase = 810;
    int yBase = 10;
    int xPos = xBase;
    int yPos = yBase;
    int yOffset = 25;
    int xOffset = 130;

    cp5.addSlider("sceneScale")
      .setLabel("scale")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(.1,1)
      .setValue(1)
     ;
    yPos+=yOffset;

    cp5.addSlider("camRotationX")
      .setLabel("camera rot X")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(-PI,PI)
      .setValue(-PI/4)
     ;
    xPos+=xOffset+50;

    cp5.addSlider("camRotationY")
      .setLabel("camera rot Y")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(-PI,PI)
      .setValue(PI/4)
     ;
     
    xPos+=xOffset+50;

    cp5.addSlider("camRotationZ")
      .setLabel("camera rot Z")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(-PI,PI)
      .setValue(0)
     ;
    
    yPos+=yOffset;
    xPos=xBase;
    cp5.addToggle("ortho")
     .setLabel("ortho")
     .setPosition(xPos, yPos)
     .setSize(50,10)
     .setValue(true)
     ;
     
     yPos+=2*yOffset;
     xPos=xBase;
     return new PVector(xPos, yPos);
  }
}
