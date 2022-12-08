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
      .setTriggerEvent(Slider.RELEASE)
      .setLabel("fill density")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(1,10)
      .setValue(1)
     ;
    
    yPos+=yOffset;
    xPos=xBase;
    
    cp5.addSlider("numContours")
      .setTriggerEvent(Slider.RELEASE)
      .setLabel("number of contours")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(1,10)
      .setValue(4)
     ;
    
    yPos+=yOffset;
    xPos=xBase;
    
    cp5.addSlider("sampleScale")
      .setTriggerEvent(Slider.RELEASE)
      .setLabel("sample scale")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(0,1)
      .setValue(.5)
     ;
    
    yPos+=yOffset;
    xPos=xBase;
    
    // this should be relative to the largest contour
    cp5.addRange("contourSizeRange")
      .setLabel("contour size range")
      .setPosition(xPos, yPos)
      .setWidth(400)
      .setRange(0.1,1)
      .setRangeValues(.001,1)
     ;
     
    yPos+=yOffset;
    xPos=xBase;
  }
}
