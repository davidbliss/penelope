// project specific parameters go here

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
    
    cp5.addSlider("sampleScale")
      .setLabel("sample scale")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(0,1)
      .setValue(.5)
     ;
    
    yPos+=yOffset;
    xPos=xBase;

    cp5.addSlider("threshold0")
      .setLabel("sample threshold 1")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(0,100)
      .setValue(20)
     ;
    
    xPos+=xOffset+50;
    cp5.addSlider("threshold1")
      .setLabel("sample threshold 2")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(0,100)
      .setValue(50)
     ;
    
    xPos+=xOffset+50;
    cp5.addSlider("threshold2")
      .setLabel("sample threshold 3")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(0,100)
      .setValue(80)
     ;
    
    yPos+=yOffset;
    xPos=xBase;
    
    // this should be relative to the largest contour
    cp5.addRange("contourSizeRange")
      .setLabel("contour size")
      .setPosition(xPos, yPos)
      .setWidth(400)
      .setRange(0,1)
      .setRangeValues(.001,1)
     ;
     
    yPos+=yOffset;
    xPos=xBase;
  }
}
