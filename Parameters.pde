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

    cp5.addSlider("fillSpacing")
      .setTriggerEvent(Slider.RELEASE)
      .setLabel("fill spacing")
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
      .setRange(2,10)
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
      .setValue(.21)
     ;
    
    yPos+=yOffset;
    xPos=xBase;
    
    // this is relative to the largest contour
    cp5.addRange("contourBrightnessRange")
      .setLabel("contour brightness range")
      .setPosition(xPos, yPos)
      .setWidth(400)
      .setRange(0,1)
      .setRangeValues(0,.5)
     ;
     
    yPos+=yOffset;
    xPos=xBase;
    
    // this is relative to the largest contour
    cp5.addRange("contourSizeRange")
      .setLabel("contour size range")
      .setPosition(xPos, yPos)
      .setWidth(400)
      .setRange(.001,1)
      .setRangeValues(.001,1)
     ;
     
    
    xPos=xBase;
    yPos+=yOffset;
    
    cp5.addSlider("contourSmoothingFactor")
      .setTriggerEvent(Slider.RELEASE)
      .setLabel("smoothing factor")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(0,10)
      .setValue(2)
     ; 
     
    yPos+=yOffset;
    xPos=xBase;
    
    cp5.addToggle("showFill")
     .setLabel("fill")
     .setPosition(xPos, yPos)
     .setSize(50,10)
     .setValue(false)
     ;

    xPos+=xOffset;
    
    cp5.addToggle("showContours")
     .setLabel("contours")
     .setPosition(xPos, yPos)
     .setSize(50,10)
     .setValue(false)
     ;
     
    xPos+=xOffset;
    
    cp5.addToggle("showKeyLines")
     .setLabel("keyLines")
     .setPosition(xPos, yPos)
     .setSize(50,10)
     .setValue(true)
     ;

    xPos=xBase;
    yPos+=yOffset;
    
    cp5.addButton("placeCenter")
      .setLabel("place center")
      .setPosition(xPos, yPos)
      .setSize(100,20)
      ;
      
    xPos=xBase;
    yPos+=yOffset;
    
    cp5.addSlider("matchDistance")
      .setTriggerEvent(Slider.RELEASE)
      .setLabel("keep contours within this distance of others")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(1,60)
      .setValue(5)
     ;
    
    xPos=xBase;
    yPos+=yOffset;
    
    cp5.addSlider("removeDistance")
      .setTriggerEvent(Slider.RELEASE)
      .setLabel("remove duplicate points within")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(1,60)
      .setValue(5)
     ;
     
    xPos=xBase;
    yPos+=yOffset;
    
    cp5.addSlider("jaggedDistance")
      .setTriggerEvent(Slider.RELEASE)
      .setLabel("max length of jagged lines")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(1,80)
      .setValue(20)
     ;
     
    xPos=xBase;
    yPos+=yOffset;
    
    cp5.addSlider("minLineLength")
      .setTriggerEvent(Slider.RELEASE)
      .setLabel("minimum length of lines drawn")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(1,80)
      .setValue(10)
     ;
    
    xPos=xBase;
    yPos+=yOffset;
    
    cp5.addSlider("minArea")
      .setTriggerEvent(Slider.RELEASE)
      .setLabel("minimum area of lines drawn")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(1,1500)
      .setValue(100)
     ;
     
    xPos=xBase;
    yPos+=yOffset;
    
    cp5.addSlider("mergeDistance")
      .setTriggerEvent(Slider.RELEASE)
      .setLabel("max distance to merge lines together")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(1,20)
      .setValue(7.5)
     ;
  }
}

Boolean waitingForCenter=false;
public void placeCenter(ControlEvent e){
  waitingForCenter = true;
}
void mousePressed() {
  if (waitingForCenter) {
    println("center clicked");
    
    centers.add(new RPoint(map(mouseX, 0, onscreenCanvasWidth, 0, canvas.width), map(mouseY, 0, onscreenCanvasHeight, 0, canvas.height)));
    waitingForCenter = false;
  }
}
