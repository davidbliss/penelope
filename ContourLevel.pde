import gab.opencv.*;
import java.util.HashMap;
import java.util.Map;

import org.opencv.core.Point;

import java.awt.Rectangle;

class ContourLevel {
  private PImage src;
  private PImage thresholdImage;
  private PImage adjustedImage;
  private ArrayList<Contour> contours;
  private OpenCV opencv;
  
  private float multiplier;
  private float offsetX;
  private float offsetY;
  private int threshold;
  
  ContourLevel(PApplet applet, PImage _src, float scale, int threshold) {
    src = _src.copy();
    
    // downsize the image so that you can identify points within contours more easily
    src.resize((int)(src.width*scale), (int)(src.height*scale)); 
   
    opencv = new OpenCV(applet, src.copy());
    opencv.gray();
    if(controls.cp5.getController("runBrightness").getValue()==1.0) opencv.brightness(int(controls.cp5.getController("brightness").getValue()));
    if(controls.cp5.getController("runContrast").getValue()==1.0) opencv.contrast(controls.cp5.getController("contrast").getValue());
    adjustedImage = opencv.getSnapshot();
    opencv.threshold(threshold);
    thresholdImage = opencv.getSnapshot();
    contours = opencv.findContours();  
    
    this.threshold = threshold;
    
    float multiplierWidth = canvas.width/(float)src.width;
    float multiplierheight = canvas.height/(float)src.height;
    multiplier = min(multiplierWidth, multiplierheight);
    
    offsetX = (canvas.width-src.width*multiplier)/2.0;
    offsetY = (canvas.height-src.height*multiplier)/2.0;
  }
  
  void simplifyCountours(float _factorLimit ){
    // the higher the _factorLimit, the more simplified
    // .75 or 1 is good for contour simplification
    // 2-2.5 is good for fills?
    
    for (int i = 0; i<contours.size(); i++){
      Contour contour = contours.get(i);
      double factor = contour.getPolygonApproximationFactor();
      if (factor > _factorLimit) factor = _factorLimit; 
      contour.setPolygonApproximationFactor(factor);
      contours.set(i, contour.getPolygonApproximation());
    }
  }  
  
  RShape getContour(Contour contour){
    RShape shape = new RShape();
    if (contour.getPoints().size() > 1) {
      
      PVector firstPoint = contour.getPoints().get(0);
      RPath path = new RPath(firstPoint.x, firstPoint.y);
      
      for (int i = 1; i<contour.getPoints().size(); i++) {
        PVector thisPoint = contour.getPoints().get(i);
        path.addLineTo(thisPoint.x, thisPoint.y);
      }      
      shape.addPath(path);
    }
    shape.addClose();
    return shape;
  }
  
  RShape getContours(){
    RShape shape = new RShape();
    for (int i = 0; i<contours.size(); i++){
      shape.addChild(getContour(contours.get(i)));
    }
    return shape;
  }
  
  int getThreshold(){
    return threshold;
  }
  
  PImage getThresholdImage(){
    return thresholdImage;
  }
  
  PImage getAdjustedImage(){
    return adjustedImage;
  }
  
  Float getMultiplier(){
    return multiplier;
  }
  
  PImage getSrc(){
    return src;
  }
  
  void removeContoursSmallerThan(float percentage){
    float maxArea = getMaxCountourArea();
    float minArea = getMinCountourArea();
    
    float areaThreshold = minArea + (maxArea-minArea) * percentage;
    
    
    for (int i=0; i<contours.size(); i++){
      if (contours.get(i).area() < areaThreshold){
        contours.remove(i);
        i--;
      }
    }
  }
  
  float getMinCountourArea(){
    float minArea = getMaxCountourArea();
    for (Contour contour : contours){
      if (contour.area()<minArea) minArea = contour.area();
    }
    return minArea;
  }
  
  float getMaxCountourArea(){
    float maxArea = 0;
    for (Contour contour : contours){
      if (contour.area()>maxArea) maxArea = contour.area();
    }
    return maxArea;
  }
  
  void removeContoursBiggerThan(float percentage){    
    float maxArea = getMaxCountourArea();
    float minArea = getMinCountourArea();
    
    
    
    float areaThreshold = minArea + (maxArea-minArea) * percentage;
    
    for (int i=0; i<contours.size(); i++){
      if (contours.get(i).area() > areaThreshold) {
        contours.remove(i);
        i--;
      }
    }
  }
  
  PVector averageClosestVector(float x, float y){
    // find closest point on all contours
    int[] results = distanceToClosestContour(x, y);
    int closestPointContour = results[1];
    int closestPointIndex = results[2];
    
    // now sum the vecotrs between this point and N points ahead
    Contour contour = contours.get(closestPointContour);
    ArrayList<PVector> points = contour.getPoints();
    
    // smallestDistance is the distance between our selected point and the target, it will be used to define the sample and the length
    
    int spread = min(5, points.size());
    
    // sampling N behind and N in front with a narrow spread has the results closest to what I was originally expecting
    int startPointIndex = closestPointIndex - spread;
    if (startPointIndex<0) startPointIndex += points.size();
    int endPointIndex = closestPointIndex+ spread;
    if (endPointIndex>=points.size()) endPointIndex -= points.size();
    PVector startPoint = points.get(startPointIndex);
    PVector endPoint = points.get(endPointIndex);
    PVector resultVector = new PVector(endPoint.x-startPoint.x, endPoint.y-startPoint.y);;
    resultVector.div(spread*2);
    return resultVector;
  }    
  
  // returns distance, index of closest contour, index of closest point closest contour
  int[] distanceToClosestContour(float x, float y){
    PVector targetPoint = new PVector(x, y);
    int smallestDistance = 10000;
    int closestPointContour = 0;
    int closestPointIndex = 0;
    for (int c = 0; c<contours.size(); c++){
      ArrayList<PVector> points = contours.get(c).getPoints();
      for (int p = 0; p<points.size()-1; p++) {
        if (distanceBetween2Points(points.get(p), targetPoint) < smallestDistance){
          smallestDistance = (int) distanceBetween2Points(points.get(p), targetPoint);
          closestPointContour = c;
          closestPointIndex = p;
        }
      }
    }
    int[] returns = {smallestDistance, closestPointContour, closestPointIndex};
    return returns;
  }
  
  PVector[] findClosestEdge(float x, float y){
    PVector targetPoint = new PVector(x, y);
    PVector[] results = new PVector[2];
    float minDistance = 10000;
    for (Contour contour : contours){
      ArrayList<PVector> points = contour.getPoints();
      if (points.size()>1){
        // check the first (and last) points in the contour
        if (distanceBetween2Points(points.get(0), targetPoint) < minDistance){
          minDistance = distanceBetween2Points(points.get(0), targetPoint);
          results[0] = points.get(0);
          if (distanceBetween2Points(points.get(1), targetPoint) < distanceBetween2Points(points.get(points.size()-1), targetPoint)){
            results[1] = points.get(0);
          } else {
            results[1] = points.get(points.size()-1);
          }
        }
        // check all other points
        for (int i = 1; i<points.size()-1; i++) {
          if (distanceBetween2Points(points.get(i), targetPoint) < minDistance){
            minDistance = distanceBetween2Points(points.get(i), targetPoint);
            results[0] = points.get(i);
            if (distanceBetween2Points(points.get(i-1), targetPoint) < distanceBetween2Points(points.get(i+1), targetPoint)){
              results[1] = points.get(i-1);
            } else {
              results[1] = points.get(i+1);
            }
          }
        }
      }
    }
    return results;
  }    
  
  PVector getRandomPointOnContour(Contour contour){
    ArrayList<PVector> points = contour.getPoints();
    int pointPick = floor(random(points.size()));
    return points.get(pointPick);
  }
  
  int getSourceWidth(){
    return src.width;
  }
  
  int getSourceHeight(){
    return src.height;
  }
  
  ArrayList<ArrayList<PVector>> getAllContoursAllPoints(){
    ArrayList<ArrayList<PVector>> allPoints = new ArrayList<ArrayList<PVector>>();
    for (Contour contour: contours){
      ArrayList<PVector> contourPoints = new ArrayList<PVector>();
      for (PVector p : contour.getPoints()){
        if(p.x>1 && p.x<src.width-2 && p.y>10 && p.y<src.height-2){
          contourPoints.add(new PVector(p.x*multiplier+offsetX, p.y*multiplier+offsetY));
        }
      }
      allPoints.add(contourPoints);
    }
    return allPoints;
  }
  
  ArrayList<PVector> getAllPoints(){
    ArrayList<PVector> allPoints = new ArrayList<PVector>();
    for (Contour contour: contours){
      for (PVector p : contour.getPoints()){
        if(p.x>1 && p.x<src.width-2 && p.y>10 && p.y<src.height-2){
          allPoints.add(new PVector(p.x*multiplier+offsetX, p.y*multiplier+offsetY));
        }
      }
    }
    return allPoints;
  }
  
  float distanceBetween2Points(int[] p1, int[] p2){
    return sqrt(pow(p1[0]-p2[0], 2)+pow(p1[1]-p2[1], 2));
  }
  
  float distanceBetween2Points(PVector p1, PVector p2){
    return sqrt(pow(p1.x-p2.x, 2)+pow(p1.y-p2.y, 2));
  }
  
  float distanceBetween2Points(float[] p1, float[] p2){
    return sqrt(pow(p1[0]-p2[0], 2)+pow(p1[1]-p2[1], 2));
  }
  
  float distanceBetween2Points(float x1, float y1, float x2, float y2){
    return sqrt(pow(x1-x2, 2)+pow(y1-y2, 2));
  }
}
