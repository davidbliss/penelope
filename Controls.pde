Group controlsGroup;

public class Controls {
  ControlP5 cp5;

  Controls(PApplet parent) {
    cp5 = new ControlP5(parent);

    init();
  }

  void init(){
    int xBase = 810;
    int yBase = 610;
    int xPos = xBase;
    int yPos = yBase;
    int yOffset = 25;
    int xOffset = 130;

    cp5.addButton("randomizeParameters")
      .setLabel("shuffle parameters")
      .setPosition(xPos, yPos)
      .setSize(100,20)
      .linebreak();
      ;
    yPos+=yOffset;
    
    cp5.addSlider("pageWidth")
      .setLabel("page width (in)")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(8,24)
      .setValue(18)
      ;
    xPos+=xOffset+50;

    cp5.addSlider("pageHeight")
      .setLabel("page height (in)")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(8,24)
      .setValue(24)
      ;
    xPos+=xOffset+50;
    
    cp5.addSlider("margin")
      .setLabel("margin (in)")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(0,2)
      .setValue(1)
      ;
    xPos+=xOffset+50;
    
    yPos+=yOffset;
    xPos=xBase;
    
    cp5.addSlider("curveFidelity")
      .setLabel("curve fidelity")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(0,1)
      .setValue(.5)
     ;
    yPos+=yOffset;

    cp5.addButton("frontCam")
      .setLabel("front")
      .setPosition(xPos, yPos)
      .setSize(100,20)
      .linebreak();
      ;
    xPos+=xOffset;

    cp5.addButton("topCam")
      .setLabel("top")
      .setPosition(xPos, yPos)
      .setSize(100,20)
      .linebreak();
      ;
    xPos+=xOffset;

    cp5.addButton("sideCam")
      .setLabel("side")
      .setPosition(xPos, yPos)
      .setSize(100,20)
      .linebreak();
      ;
    xPos+=xOffset;

    cp5.addButton("angleCam")
      .setLabel("angle")
      .setPosition(xPos, yPos)
      .setSize(100,20)
      .linebreak();
      ;

    yPos+=yOffset;
    xPos=xBase;

    cp5.addButton("regenerate")
      .setLabel("regenerate")
      .setPosition(xPos, yPos)
      .setSize(100,20)
      ;
    yPos+=yOffset;

    cp5.addButton("saveSnapshot")
      .setLabel("save image")
      .setPosition(xPos, yPos)
      .setSize(100,20)
      ;
    
    xPos+=xOffset;
    cp5.addButton("loadFromFile")
     .setLabel("load image")
     .setPosition(xPos, yPos)
     .setSize(100,20)
     ;
    yPos+=yOffset;
  }


}
