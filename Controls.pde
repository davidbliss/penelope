// TODO: possible ideas for future:
  // break out images controls to include load and basic brightness/contrast controls

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
      .setTriggerEvent(Slider.RELEASE)
      .setLabel("page width (in)")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(8,24)
      .setValue(18)
      ;
    xPos+=xOffset+50;

    cp5.addSlider("pageHeight")
      .setTriggerEvent(Slider.RELEASE)
      .setLabel("page height (in)")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(8,24)
      .setValue(24)
      ;
    xPos+=xOffset+50;
    
    cp5.addSlider("margin")
      .setTriggerEvent(Slider.RELEASE)
      .setLabel("margin (in)")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(0,2)
      .setValue(1)
      ;
    xPos+=xOffset+50;
    
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

// FUNCTIONS FOR CONTROLS
public void saveSnapshot(){
  String output = "";
  canvas.saveImage(output);
}

void randomizeParameters(){
  parameters.manager.randomize();
  regenerate();
}

void regenerate(){  
}

public void controlEvent(ControlEvent theEvent){
  // controlEvent is called before the program's setup is complete.
  // calling drawOnce before program is complete generates error
  
  if(canvas != null && theEvent.getName() != "loadFromFile" && theEvent.getName() != "saveSnapshot"){
    if(loadedImage!=null) drawing.processImage();
    drawRequested = true;
  }
}

void loadFromFile(){
  selectInput("Select a file to process:", "loadImageFromDisk");
}

void loadImageFromDisk(File selection){
  if (selection == null) {
    println("dialog closed or canceled.");
  } else {
    String path = selection.getAbsolutePath();
    println("loading image:", path);
    loadedImage = loadImage(path);
    drawing.processImage();
    drawRequested = true;
  }
}
