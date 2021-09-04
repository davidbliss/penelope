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
    yPos+=yOffset;
  }


}
