// imports used throughout

import java.util.List;
import java.util.ArrayList;
import java.util.HashMap;

import geomerative.RG;
import geomerative.RPath;
import geomerative.RPoint;
import geomerative.RShape;
import geomerative.RCommand;

import controlP5.*;

// globals used throughout
Parameters parameters;  // drawing parameters that can be shuffled
Controls controls;      // drawing controls and parameters that are not shuffled

ColorManager colorManager = new ColorManager();
GeoUtils geoUtils = new GeoUtils();

PenelopeCanvas canvas;
Drawing drawing;
PImage loadedImage;

int numCanvases = 3;

int onscreenCanvasWidth;
int onscreenCanvasHeight;

void setup() {
  size(1400,800,P3D); // 1400,800 fits well on my laptop
  background(25);
  
  parameters = new Parameters(this);
  controls = new Controls(this);
  canvas = new PenelopeCanvas(this, numCanvases);
  
  initDrawing();
}

void draw(){
  // draw needs to be here even if empty
}

// do things here that need to be done each time drawing is regenerated
void initDrawing(){
  setupCanvas();
  canvas.clear();
  background(25);
  
  // initial OffscreenCanvas background is not drawn, so we draw it manually here.
  fill(255);
  rect(0,0,onscreenCanvasWidth,onscreenCanvasHeight);
  noFill();

  // create the drawing object
  drawing = new Drawing();
  drawing.draw(canvas);
  
  drawCanvas();
}

void setupCanvas(){
  // since page width and height can be changed, this is called 
  canvas.setDimensions();

  // calculate the onscreen canvas width and height
  float scale;
  if(canvas.width < canvas.height){
    scale = (float) height / canvas.height;
  } else {
    scale = (float) height / canvas.width;
  }
  onscreenCanvasWidth = (int) (canvas.width * scale);
  onscreenCanvasHeight = (int) (canvas.height * scale);
}

void drawCanvas(){
  canvas.draw();
  image(canvas.graphics, 0, 0, onscreenCanvasWidth, onscreenCanvasHeight);
}
