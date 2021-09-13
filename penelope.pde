import processing.svg.*;

Parameters parameters;  // drawing parameters that can be shuffled
Controls controls;      // drawing controls and parameters that are not shuffled

Drawing drawing;

ArrayList<PenelopeCanvas> canvases;
int numCanvases = 3;

int onscreenCanvasWidth;
int onscreenCanvasHeight;

void setup() {
  size(1400,800,P3D); // 1400,800 fits well on my laptop
  background(25);

  parameters = new CubeParameters(this);
  controls = new Controls(this);
  
  init();
}

// do things here that need to be done each time drawing is regenerated
void init(){
  canvases = new ArrayList<PenelopeCanvas>();
  for (int i = 0; i < numCanvases; i++){
    PenelopeCanvas newCanvas = new PenelopeCanvas(parameters, controls);
    newCanvas.graphics.beginDraw(); // if we later try to draw the graphics, and nothing is there, it throws error... 
    newCanvas.graphics.endDraw();   // these two lines prevent that error in case Drawing does not put something into the canvas
    canvases.add(newCanvas);
  }

  // calculate the onscreen canvas width and height
  PGraphics graphics = canvases.get(0).graphics;
  float scale;
  if(canvases.get(0).graphics.width<graphics.height){
    scale = float(height) / graphics.height;
  } else {
    scale = float(height) / graphics.width;
  }
  onscreenCanvasWidth = int(graphics.width * scale);
  onscreenCanvasHeight = int(graphics.height * scale);

  // initial OffscreenCanvas background is not drawn, so we draw it manually here.
  fill(255);
  rect(0,0,onscreenCanvasWidth,onscreenCanvasHeight);

  // create the drawing object
  drawing = new Drawing(parameters);

  // initial drawing
  initDrawing();
}

void draw(){
  // draw needs to be here even if empty
}

void initDrawing(){
  // generate the drawing
  drawing.generate();

  // draw it offscreen
  drawing.draw(canvases);
  
  // draw the preview to the screen.
  for (PenelopeCanvas canvas : canvases){
    image(canvas.graphics, 0, 0, onscreenCanvasWidth, onscreenCanvasHeight);
  }
}

// FUNCTIONS FOR CONTROLS
void frontCam(){
  println("front cam");
  parameters.cp5.getController("camRotationX").setValue(0);
  parameters.cp5.getController("camRotationY").setValue(0);
  parameters.cp5.getController("camRotationZ").setValue(0);
}

void topCam(){
  parameters.cp5.getController("camRotationX").setValue(0);
  parameters.cp5.getController("camRotationY").setValue(PI/2);
  parameters.cp5.getController("camRotationZ").setValue(0);
}

void sideCam(){
  parameters.cp5.getController("camRotationX").setValue(0);
  parameters.cp5.getController("camRotationY").setValue(0);
  parameters.cp5.getController("camRotationZ").setValue(PI/2);
}

void angleCam(){
  parameters.cp5.getController("camRotationX").setValue(-PI/4);
  parameters.cp5.getController("camRotationY").setValue(PI/4);
  parameters.cp5.getController("camRotationZ").setValue(0);
}

void saveSnapshot(){
  ArrayList<PenelopeCanvas> svgs = new ArrayList<PenelopeCanvas>();
  
  drawing.draw(canvases);
  
  String name = "output/"+month()+"."+day()+"."+year()+"_"+hour()+"-"+minute()+"-"+second();
  int layerNum = 1;
  for (PenelopeCanvas layer : canvases){
    layer.saveImage(name+"-layer-"+layerNum);
    svgs.add(new PenelopeCanvas(createGraphics(canvases.get(0).graphics.width, canvases.get(0).graphics.height, SVG, name+"-layer-"+layerNum+".svg"), parameters, controls));
    layerNum++;
  }
  parameters.manager.saveValues(name);
  
  // draw to SVG layers, which triggers save
  drawing.draw(svgs);
}

void randomizeParameters(){
  parameters.manager.randomize();
  regenerate();
}

void regenerate(){  
  init();
}
