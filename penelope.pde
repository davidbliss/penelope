// TODO: figure out an approach to layers (colors/width)

import processing.svg.*;

Parameters parameters;  // drawing parameters that can be shuffled
Controls controls;      // drawing controls and parameters that are not shuffled

Drawing drawing;

PenelopeCanvas preview;

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
  preview = new PenelopeCanvas(parameters, controls);

  // calculate the onscreen canvas width and height
  float scaler;
  if(preview.graphics.width<preview.graphics.height){
    scaler =  float(height) / preview.graphics.height;
  } else {
    scaler =  float(height) / preview.graphics.width;
  }
  onscreenCanvasWidth = int(preview.graphics.width * scaler);
  onscreenCanvasHeight = int(preview.graphics.height * scaler);

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
  drawing.draw(preview);

  // draw the preview to the screen.
  image(preview.graphics, 0, 0, onscreenCanvasWidth, onscreenCanvasHeight);
}

// FUNCTIONS FOR CONTROLS
// TODO: would be nice to move these to controls but CP5 is being difficult
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

// TOODO: move to Canvas?
void saveSnapshot(){
  String name = "output/"+month()+"."+day()+"."+year()+"_"+hour()+"-"+minute()+"-"+second();
  preview.saveImage(name);
  parameters.manager.saveValues(name);

  // make an svg with the correct path and draw to it
  PenelopeCanvas svg = new PenelopeCanvas(createGraphics(preview.graphics.width, preview.graphics.height, SVG, name+".svg"), parameters, controls);
  drawing.draw(svg);
}

void randomizeParameters(){
  parameters.manager.randomize();
  regenerate();
}

void regenerate(){
  if(preview!=null) {
    init();
    preview.clear();
    drawing.generate();
    initDrawing();
  }
}
