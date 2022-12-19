public class Controls {
  ControlP5 cp5;

  Controls(PApplet parent) {
    cp5 = new ControlP5(parent);

    init();
  }

  void init(){
    int xBase = 810;
    int yBase = 460;
    int xPos = xBase;
    int yPos = yBase;
    int yOffset = 25;
    int xOffset = 180;
    
    cp5.addButton("loadFromFile")
     .setLabel("load image")
     .setPosition(xPos, yPos)
     .setSize(100,20)
     ;
    yPos+=yOffset;
    
    // 0 is same as not running the filter
    cp5.addSlider("brightness")
      .setTriggerEvent(Slider.RELEASE)
      .setLabel("brightness")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(-255,255)
      .setValue(0)
      ;
    xPos+=xOffset;
    
    cp5.addToggle("runBrightness")
     .setLabel("brightness")
     .setPosition(xPos, yPos)
     .setSize(50,10)
     .setValue(true)
     ;
    xPos=xBase;
    yPos+=yOffset;

    // 1 is same as not running filter
    cp5.addSlider("contrast")
      .setTriggerEvent(Slider.RELEASE)
      .setLabel("contrast")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(0,3)
      .setValue(1)
      ;
    xPos+=xOffset;
    
    cp5.addToggle("runContrast")
     .setLabel("contrast")
     .setPosition(xPos, yPos)
     .setSize(50,10)
     .setValue(true)
     ;
    xPos=xBase;
    yPos+=yOffset;
    
    cp5.addToggle("showImage")
     .setLabel("show image")
     .setPosition(xPos, yPos)
     .setSize(50,10)
     .setValue(false)
     ;
    yPos+=yOffset*2;
    
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
      .setRange(5,24)
      .setValue(8)
      ;
    xPos+=xOffset;

    cp5.addSlider("pageHeight")
      .setTriggerEvent(Slider.RELEASE)
      .setLabel("page height (in)")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(5,24)
      .setValue(5)
      ;
    xPos+=xOffset;
    
    cp5.addSlider("margin")
      .setTriggerEvent(Slider.RELEASE)
      .setLabel("margin (in)")
      .setPosition(xPos, yPos)
      .setWidth(100)
      .setRange(0,2)
      .setValue(1)
      ;
    xPos+=xOffset;
    
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

    cp5.addButton("loadSettingsFile")
      .setLabel("load settings")
      .setPosition(xPos, yPos)
      .setSize(100,20)
      ;
    
    
  }
}

// FUNCTIONS FOR CONTROLS
public void saveSnapshot(){
  canvas.saveImage();
}

void randomizeParameters(){
  parameters.manager.randomize();
  regenerate();
}

void regenerate(){  
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
    drawRequested = true;
  }
}

void loadSettingsFile(){
  selectInput("Select a settings file to import:", "loadSettings");
}

void loadSettings(File selection){
  if (selection == null) {
    println("dialog closed or canceled.");
  } else {
    String path = selection.getAbsolutePath();
    println("loading settings:", path);
    String[] lines = loadStrings(path);
    for (int i = 0 ; i < lines.length; i++) {
      int comIndex = lines[i].indexOf(",");
      int colIndex = lines[i].indexOf(":"); 
      
      if(comIndex >0){
        String control = lines[i].substring(comIndex+2,colIndex);
        String value = lines[i].substring(colIndex+2);
        
        if(parameters.cp5.getController(control) != null) {
          parameters.cp5.getController(control).setValue(float(value));
        } else {
          println("parameter", control, "not found");
        }
      }
    }
  }
}
