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

int numCanvasLayers = 3;

int onscreenCanvasWidth;
int onscreenCanvasHeight;

boolean drawRequested;

void setup() {
  size(1400,800,P3D); // 1400,800 fits well on my laptop
  background(25);
  
  parameters = new Parameters(this);
  controls = new Controls(this);
  canvas = new PenelopeCanvas(this, numCanvasLayers);
  drawing = new Drawing(this, 1);
  
  drawRequested = true;
}

void draw(){
  // draw needs to be here even if empty
  if(drawRequested == true){
    drawOnce();
    drawRequested = false;
  }
}

void drawOnce(){
  updateDimensions();
  
  background(25);
  
  // initial OffscreenCanvas background is not drawn, so we draw it manually here.
  fill(255);
  rect(0,0,onscreenCanvasWidth,onscreenCanvasHeight);
  noFill();
  
  canvas.clear();
  drawing.draw(canvas);
  
  canvas.draw();
  image(canvas.graphics, 0, 0, onscreenCanvasWidth, onscreenCanvasHeight);
}

void updateDimensions(){
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

public void controlEvent(ControlEvent theEvent){
  // triggered by controls and parameters
  if(canvas != null && theEvent.getName() != "loadFromFile" && theEvent.getName() != "saveSnapshot" && theEvent.getName() != "placeCenter"){
    drawRequested = true;
  }
}
