
// TODO: figure out an approach to layers (colors/width)

import processing.svg.*;

boolean oneFrameDrawn;

Parameters parameters; // drawing parameters that can be shuffled
Controls controls;

Drawing drawing;

float camRotationX;
float camRotationY;

OffscreenCanvas preview;

int canvasWidth;
int canvasHeight;

int offscreenCanvasMargin;

void setup() {
  size(1400,800,P3D); // 1400,800 fits well on my laptop
  background(25);

  parameters = new Parameters(this);
  controls = new Controls(this);

  init();
}

void init(){
  // things that may change when controls are updated
  float scaleAdjust = 71.95;

  // calculate the height and width of the offscreen bits.
  int offscreenCanvasWidth = int(controls.cp5.getController("pageWidth").getValue() * scaleAdjust);
  int offscreenCanvasHeight = int(controls.cp5.getController("pageHeight").getValue() * scaleAdjust);
  offscreenCanvasMargin = int(controls.cp5.getController("margin").getValue() * scaleAdjust);

  preview = new OffscreenCanvas(offscreenCanvasWidth, offscreenCanvasHeight);

  // calculate the onscreen width and height
  float scaler;
  if(preview.graphics.width<preview.graphics.height){
    scaler =  float(height) / preview.graphics.height;
  } else {
    scaler =  float(height) / preview.graphics.width;
  }
  canvasWidth = int(preview.graphics.width * scaler);
  canvasHeight = int(preview.graphics.height * scaler);


  // initial OffscreenCanvas background is not drawn, so we draw it manually here.
  fill(255);
  rect(0,0,canvasWidth,canvasHeight);

  // create the drawing object
  drawing = new Drawing(parameters);

  // initial drawing
  drawOnce();
}

void draw(){
  // draw needs to be here even if empty
}

void drawOnce(){
  // drawing specific things

  // make new chains
  drawing.makeChains();

  // draw it offscreen
  drawDrawing(preview);

  // draw the preview to the screen.
  image(preview.graphics, 0, 0, canvasWidth, canvasHeight);
}

// this is used to draw to screen and draw to offscreen SVG when saving... must keep separate from drawOnce command
void drawDrawing(OffscreenCanvas canvas){
  canvas.preDraw3d();
  drawing.draw(canvas);
  canvas.postDraw3d();
}

// FUNCTIONS FOR CONTROLS

void frontCam(){
  parameters.cp5.getController("camRotationX").setValue(0);
  parameters.cp5.getController("camRotationY").setValue(0);
}

void sideCam(){
  parameters.cp5.getController("camRotationX").setValue(PI/2);
  parameters.cp5.getController("camRotationY").setValue(0);
}

void topCam(){
  parameters.cp5.getController("camRotationX").setValue(0);
  parameters.cp5.getController("camRotationY").setValue(PI/2);
}

void angleCam(){
  parameters.cp5.getController("camRotationX").setValue(-PI/4);
  parameters.cp5.getController("camRotationY").setValue(PI/4);
}

void saveSnapshot(){
  String name = "output/"+month()+"."+day()+"."+year()+"_"+hour()+"-"+minute()+"-"+second();
  preview.saveImage(name);
  parameters.manager.saveValues(name);

  // make an svg with the correct path and draw to it
  OffscreenCanvas svg = new OffscreenCanvas(createGraphics(preview.graphics.width, preview.graphics.height, SVG, name+".svg"));
  drawDrawing(svg);
}

void randomizeParameters(){
  parameters.manager.randomize();
  regenerate();
}

void regenerate(){
  if(preview!=null) {
    init();
    preview.clear();
    drawing.init();
    drawOnce();
  }
}
