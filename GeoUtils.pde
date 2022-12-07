import java.util.ArrayList;
import java.util.HashMap;

import geomerative.RG;
import geomerative.RPath;
import geomerative.RPoint;
import geomerative.RShape;

//TODO: some functions in this class(like filterJaggedLines) handle nested shapes, others (like thickenLines) do not; need to come to terms with that to improve reusability

public class GeoUtils {
  public RPoint[] sortPoints (RPoint[] points, RPoint basePoint, float startDistance) {
    RPoint[] sortedPoints = new RPoint[points.length];
    for(int j=0; j<points.length; j++) {
      float minDistance = startDistance;
      int closestIndex = 0;
      for(int k=0; k<points.length; k++) {
        if(basePoint.dist(points[k])<minDistance) {
          minDistance = basePoint.dist(points[k]);
          closestIndex = k;
        }
      }
      sortedPoints[j]=new RPoint(points[closestIndex]);
      points[closestIndex].x=startDistance;
      points[closestIndex].y=startDistance;
    }
    return sortedPoints;
  }
  
  public RShape iterativelyFill(RShape _layer, float fillDensity, boolean vertical) {
    RShape fills = new RShape();
    _layer.width = width;
    _layer.height = height;
    if (_layer.children!=null) {
      for(RShape child: _layer.children) {
        fills.addChild(iterativelyFill(child, fillDensity, vertical));
      }
    } else {
      RShape thisfills = hatchFill(_layer, fillDensity, vertical); 
      thisfills = geoUtils.mergeLines(thisfills,fillDensity*1.25f);
      if(thisfills.children!=null) {
        for (RShape child: thisfills.children) {
          child.setFill("none");
        }
      }
      fills.addChild(thisfills);
    }
    
    return fills;
  }
  
  public RShape hatchFill(RShape shape, float _spacing, boolean vertical) {
    // NOTE: Added to support shapes more generically, might not work in apps using previous hatchFill.
    // This only recognizes holes if the paths are combined as one.
    ArrayList<ArrayList<RPoint>> hatches = new ArrayList<ArrayList<RPoint>>();
   
    int minDim = (vertical==true)? (int)shape.getTopLeft().x : (int)shape.getTopLeft().y;
    int maxDim = (vertical==true)? (int)shape.getTopLeft().x + (int)shape.getWidth() : (int)shape.getTopLeft().y + (int)shape.getHeight();
    
    
    for (float l=minDim-10; l<maxDim+10; l+=_spacing) {  // NOTE: get height is not reliable for all shapes adding some buffer
      RPoint lineBegin = new RPoint(l,0);
      RShape cuttingLine = RG.getLine(lineBegin.x, lineBegin.y-100, l, shape.width+100);
      if (vertical==false) {
        lineBegin = new RPoint(0,l);
        cuttingLine = RG.getLine(lineBegin.x-100, lineBegin.y, shape.width+100, l);
      }
      
      RPoint[] points = shape.getIntersections(cuttingLine);
      
      if(points!=null) {
        // these intersection points are not in order. we have to sort them first.
        RPoint[] sortedPoints = geoUtils.sortPoints(points,lineBegin,shape.height*shape.height);

        int iterLength = sortedPoints.length;
        if(sortedPoints.length%2!=0) {
          println("odd number of points");
          iterLength = sortedPoints.length-1;
        }
        for(int p=0; p<iterLength; p+=2) {
          if(sortedPoints[p].dist(sortedPoints[p+1])>.5f) {
            hatches.addAll(geoUtils.subdivideLine(sortedPoints[p], sortedPoints[p+1], 0, 1));
          }
        }
      }
    }
    RShape shapeHatches = pointsToShape(hatches);
    shapeHatches.setStrokeWeight(.5f);
    shapeHatches.setFillAlpha(0);
    return shapeHatches;
  }
  
  public ArrayList<ArrayList<RPoint>> subdivideLine(RPoint p1, RPoint p2, float _brightness, float _detailScale){
    ArrayList<ArrayList<RPoint>> linesPoints = new ArrayList<ArrayList<RPoint>>();
    
    if (_brightness==0) {
      // if it is meant to be black, just one long line
      ArrayList<RPoint> linePoints = new ArrayList<RPoint>();
      linePoints.add(p1);
      linePoints.add(p2);
      linesPoints.add(linePoints);
    } else if (_brightness!=1) {
      // if meant to be white, don't draw anything
      
      // now handle shades between

      // pick a slightly randomized number of segments based on the brightness and line length
      
      float lineLength = p1.dist(p2);
      float topRange = min(50*_detailScale,lineLength);
      float combinedLength = random(20*_detailScale,topRange);
      if(combinedLength>lineLength) combinedLength=lineLength;
      
      
      int numSegments = (int) (lineLength / combinedLength);
      
      float combinedLengthAdj = lineLength / numSegments / lineLength; // normalized
      
      // calculate (normalized) segment length based on number segments and fillPercent
      // middle floatskews things a bit toward void length to account for pen width
      float segLength = (1f-_brightness) * .8f * combinedLengthAdj; 
      float voidLength = (combinedLengthAdj - segLength);
      
      
      if (segLength*lineLength > 4  || _brightness < .3) {
        
        RShape line = RG.getLine(p1.x,  p1.y,  p2.x,  p2.y);
        if(segLength*lineLength <= 4 && _brightness < .3) {
          // just one line
          ArrayList<RPoint> linePoints = new ArrayList<RPoint>();
          linePoints.add(p1);
          linePoints.add(p2);
          linesPoints.add(linePoints);
        } else {
          // find points along the path using geomerative
          float start = random(voidLength);
          for(int i=0; i<numSegments; i++) {
            line.insertHandle(start);
            float end = start + segLength;
            line.insertHandle(end);
            start = end+voidLength;
          }
          RPoint[] points = line.getPoints();
          for (int i=1; i<points.length-2; i+=2) { // NOTE: using the insertHandle technique to have geometarive find the points generates an duplicate handle at the end.
            ArrayList<RPoint> linePoints = new ArrayList<RPoint>();
            linePoints.add(points[i]);
            linePoints.add(points[i+1]);
            linesPoints.add(linePoints);
            
          }
        }
      }
    }
    return linesPoints;
  }
  
  // used in image contours
  public RShape findKeyContours(RShape _allContours, float _matchDistance, float _removeDistance) {
    ArrayList<ArrayList<RPoint>> keyPaths = new ArrayList<ArrayList<RPoint>> ();
    
    HashMap<String, Integer> removePoint = new HashMap<String, Integer>();
        
    // build list of all pathPoints grouped by contours
    ArrayList<ArrayList<ArrayList<RPoint>>> allContoursPathPoints = new ArrayList<ArrayList<ArrayList<RPoint>>>();
    
    for (int cnt=0; cnt<_allContours.children.length; cnt++) {
      RShape contour = _allContours.children[cnt];
      ArrayList<ArrayList<RPoint>> allPathPoints = getPathPoints(contour);
      allContoursPathPoints.add(allPathPoints);
    }
      
    // since all contours are included in one Shape, each contour in a child shape, we first cycle through children
    for (int scnt=0; scnt<_allContours.children.length; scnt++) {
      int cnt;
      
      if(scnt%2==0) cnt = scnt/2;
      else cnt = (_allContours.children.length-1) - (scnt-1)/2;
      
      if(cnt >=_allContours.children.length)cnt-=_allContours.children.length;
      

      ArrayList<ArrayList<RPoint>> allPaths = allContoursPathPoints.get(cnt);
      
      // find paths with other paths close to them (these represent contours with high contrast AKA the key paths to render).
      for(int pth=0; pth<allPaths.size(); pth++) {
        ArrayList<RPoint> path = allPaths.get(pth);
        ArrayList<RPoint> newPath = new ArrayList<RPoint>();
        ArrayList<RPoint> pathCopy = new ArrayList<RPoint>();
        for(int pnt=0; pnt<path.size(); pnt++) {
          RPoint point = path.get(pnt);
          // compare this point to every other point in paths that come later
          int nearPointCount = 0;
          for (int ccnt=0; ccnt<_allContours.children.length; ccnt++) {
            ArrayList<ArrayList<RPoint>> compContour = allContoursPathPoints.get(ccnt);
            contourloop:
            if(cnt!=ccnt) {
              for(int cpth=0; cpth<compContour.size(); cpth++) {
                ArrayList<RPoint> compPath = compContour.get(cpth);
                for(int cpnt=0; cpnt<compPath.size(); cpnt++) {
                  RPoint compPoint = compPath.get(cpnt);
                  // first pass, shorter distance, remove points
                  // NOTE: _removeDistance is a great variable to change to get different levels of detail 
                  // .5 the _matchDistance is too little detail for most (but not all)
                  // .25 _matchDistance is much better, (possibly idea for water color? or hatch fill) but lacks contrast for stand alone line drawing.  
                  // for 20 levels of contours .125 _matchDistance is quite nice for many. (.25 or even .5 is better for some)
                  // for 10 levels of contours it is best to skip this step
                  if (point.dist(compPoint) <= _removeDistance) {
                    int count = 0;
                    if (removePoint.get(ccnt+","+cpth+","+cpnt)!=null) count = removePoint.get(ccnt+","+cpth+","+cpnt);
                    removePoint.put(ccnt+","+cpth+","+cpnt, count+1);
                  }
                  
                  // second, longer distance, count points
                  if (point.dist(compPoint) <= _matchDistance) {
                    nearPointCount++;
                    break contourloop; // only each other contour once.
                  }
                }
              }
            }
          }

          pathCopy.add(new RPoint(point));
          
          if(nearPointCount > 0) {
            newPath.add(new RPoint(point));
          } else {
            // if this point is not good, but you have a path with some points that lead up to this, break that path and start a new one
            if(newPath.size() > 0) {
              keyPaths.add(newPath);
              newPath = new ArrayList<RPoint>();
            }
          }
        }
        // finished running through all points in this path.
        
        keyPaths.add(newPath);
        
        
      }
      // finished cycling through all paths in this contour
      // remove points from other paths that were matched when building this path
      // since you will be removing points as you go. work from the back.
      for(int cntIndex=allContoursPathPoints.size()-1; cntIndex>=0; cntIndex--) {
        for(int pthIndex=allContoursPathPoints.get(cntIndex).size()-1; pthIndex>=0; pthIndex--) {
          ArrayList<RPoint> pathToAlter = allContoursPathPoints.get(cntIndex).get(pthIndex);
          for(int pntIndex=pathToAlter.size()-1; pntIndex>=0; pntIndex--) {
            if(removePoint.get(cntIndex+","+pthIndex+","+pntIndex)!=null && removePoint.get(cntIndex+","+pthIndex+","+pntIndex)>1) {
              if(pntIndex==0 || pntIndex==pathToAlter.size()-1) {
                // if the point is the first or last, remove it and save path into allpaths
                pathToAlter.remove(pntIndex);
                allContoursPathPoints.get(cntIndex).set(pthIndex, pathToAlter);
              } else {
                // if point is mid path, remove the full path and make two new partial paths
                ArrayList<RPoint> firstPart = new ArrayList<RPoint>(pathToAlter.subList(0,pntIndex));
                ArrayList<RPoint> secondPart = new ArrayList<RPoint>(pathToAlter.subList(pntIndex+1, pathToAlter.size()));
                pathToAlter = firstPart;
                allContoursPathPoints.get(cntIndex).set(pthIndex, firstPart);
                allContoursPathPoints.get(cntIndex).add(secondPart);
              }
              removePoint.put(cntIndex+","+pthIndex+","+pntIndex,0);
            }
          }
        }
      }
    }
    // finished cycling through each contour
    
    return pointsToShape(keyPaths);
  }
  
  public RShape filterShortLines(RShape _allShapes, float _distance) {
    ArrayList<ArrayList<RPoint>> filteredPaths = new ArrayList<ArrayList<RPoint>> ();
    
    for (int cnt=0; cnt<_allShapes.children.length; cnt++) {
      RShape shape = _allShapes.children[cnt];
      RPoint[][] allPathPoints = shape.getPointsInPaths();
      
      if (allPathPoints!=null) {
        for(int pthpnts=0; pthpnts<allPathPoints.length; pthpnts++) {
          RPoint[] pathPoints = allPathPoints[pthpnts];
          if(pathPoints!=null) {
            float pathLength=0;
            ArrayList<RPoint> newPath = new ArrayList<RPoint>();
            
            for (int pnt=0; pnt<pathPoints.length-1; pnt++) {
              pathLength += pathPoints[pnt].dist(pathPoints[pnt+1]);
            }
            
            if (pathLength>_distance) {
              for (int pnt=0; pnt<pathPoints.length; pnt++) {
                newPath.add(pathPoints[pnt]);
              }
              filteredPaths.add(newPath);
            }
          }
        }
      }
    }
    
    return pointsToShape(filteredPaths);
  }
  
  public RShape filterSmallArea(RShape _allShapes, float _area) {
    ArrayList<ArrayList<RPoint>> filteredPaths = new ArrayList<ArrayList<RPoint>> ();
    
    for (int cnt=0; cnt<_allShapes.children.length; cnt++) {
      RShape shape = _allShapes.children[cnt];
      RPoint[][] allPathPoints = shape.getPointsInPaths();
      
      if (allPathPoints!=null) {
        for(int pthpnts=0; pthpnts<allPathPoints.length; pthpnts++) {
          RPoint[] pathPoints = allPathPoints[pthpnts];
          if(pathPoints!=null) {
            float maxx=0;
            float minx=MAX_FLOAT;
            float maxy=0;
            float miny=MAX_FLOAT;
            
            
            for (int pnt=0; pnt<pathPoints.length; pnt++) {
              maxx = max(maxx, pathPoints[pnt].x);
              minx = min(minx, pathPoints[pnt].x);
              maxy = max(maxy, pathPoints[pnt].y);
              miny = min(miny, pathPoints[pnt].y);
            }
            
            if((maxy-miny)*(maxx-minx)>_area) {
              ArrayList<RPoint> newPath = new ArrayList<RPoint>();
              for (int pnt=0; pnt<pathPoints.length; pnt++) {
                newPath.add(new RPoint(pathPoints[pnt].x, pathPoints[pnt].y));
              }
              filteredPaths.add(newPath);
            }
          }
        }
      }
    }
    
    return pointsToShape(filteredPaths);
  }
  
  public RShape mergeLines(RShape _allShapes, float _distance) {
    ArrayList<ArrayList<RPoint>> filteredPaths = new ArrayList<ArrayList<RPoint>> ();
      
    ArrayList<ArrayList<RPoint>> allPathPoints = getPathPoints(_allShapes);
  
    if (allPathPoints!=null) {
      for(int pth=0; pth<allPathPoints.size(); pth++) {
        ArrayList<RPoint> pathPoints = allPathPoints.get(pth);
        
        if(pathPoints!=null && pathPoints.size()>0) {
//            println("pth",pth, pathPoints.length);
          ArrayList<RPoint> newPath = new ArrayList<RPoint>();
          for(int pnts=0; pnts<pathPoints.size(); pnts++) {
            newPath.add(new RPoint(pathPoints.get(pnts)));
          }
          otherPathLoop:
          for(int otherpth=allPathPoints.size()-1; otherpth>=0; otherpth--) {
            ArrayList<RPoint> otherPathPoints = allPathPoints.get(otherpth);
            if(pth!=otherpth && otherPathPoints!=null && otherPathPoints.size()>0) {
              // if last point of this path is in close proximity to first of another, merge them (and run this again)
              if (pathPoints.get(pathPoints.size()-1).dist(otherPathPoints.get(0))<_distance) {
//                  println("merge found",otherpth);
                // merge other into pathPoint
                ArrayList<RPoint> mergedPathPoints = new ArrayList<RPoint>();
                for(int pnts=0; pnts<pathPoints.size(); pnts++) {
                  mergedPathPoints.add(new RPoint(pathPoints.get(pnts)));
                }
                for(int pnts=0; pnts<otherPathPoints.size(); pnts++) {
                  mergedPathPoints.add(new RPoint(otherPathPoints.get(pnts)));
                }
                allPathPoints.set(pth, mergedPathPoints);
                allPathPoints.set(otherpth, new ArrayList<RPoint>());
                pth--; //run it again with the new version
                newPath = new ArrayList<RPoint>();
                break otherPathLoop;
              }
              // if not, if last point of this path is close to last point of another, merge them (and run this again)
              if (pathPoints.get(pathPoints.size()-1).dist(otherPathPoints.get(otherPathPoints.size()-1))<_distance) {
//                  println("merge found",otherpth);
                // merge other into pathPoint
                ArrayList<RPoint> mergedPathPoints = new ArrayList<RPoint>();
                for(int pnts=0; pnts<pathPoints.size(); pnts++) {
                  mergedPathPoints.add(new RPoint(pathPoints.get(pnts)));
                }
                for(int pnts=0; pnts<otherPathPoints.size(); pnts++) {
                  mergedPathPoints.add(new RPoint(otherPathPoints.get(otherPathPoints.size()-1-pnts))); // reverse point order
                }
                allPathPoints.set(pth, mergedPathPoints);
                allPathPoints.set(otherpth, new ArrayList<RPoint>());
                pth--; //run it again with the new version
                newPath = new ArrayList<RPoint>();
                break otherPathLoop;
              }
            }
          }
          filteredPaths.add(newPath);
        }
      }
    }
      
    return pointsToShape(filteredPaths);
  }
  
  public RShape filterJaggedLines(RShape _allShapes, float _distance) {
    ArrayList<ArrayList<RPoint>> filteredPaths = new ArrayList<ArrayList<RPoint>> ();
    
    for (int cnt=0; cnt<_allShapes.children.length; cnt++) {
      RShape shape = _allShapes.children[cnt];

      ArrayList<ArrayList<RPoint>> allPathPoints = getPathPoints(shape);
      
      int jaggedCount = 0;
      
      if (allPathPoints!=null) {
        for(int pthpnts=0; pthpnts<allPathPoints.size(); pthpnts++) {
          ArrayList<RPoint> pathPoints = allPathPoints.get(pthpnts);
          if(pathPoints!=null) {
            float previousAngle = angleBetween(pathPoints.get(0), pathPoints.get(1));
            ArrayList<RPoint> newPath = new ArrayList<RPoint>();
            newPath.add(new RPoint(pathPoints.get(0)));
            newPath.add(new RPoint(pathPoints.get(1)));
            
            for (int pnt=1; pnt<pathPoints.size()-1; pnt++) {
              // difference of angle for two lines, three points at at time
              float thisAngle = angleBetween(pathPoints.get(pnt), pathPoints.get(pnt+1));
              float thisDistance = pathPoints.get(pnt).dist(pathPoints.get(pnt+1));
              
              float d1 = abs(thisAngle-previousAngle);
                float d2 = min(thisAngle,previousAngle) + TWO_PI - max(thisAngle,previousAngle);
                if(min(d1,d2) > 1.5 && thisDistance < _distance/4)  jaggedCount++;
                else if(min(d1,d2) > 2.4 && thisDistance < _distance/2.6)  jaggedCount++;
                else if(min(d1,d2) > 2.9 && thisDistance < _distance)  jaggedCount++;
              
              if(jaggedCount < 1) {
                newPath.add(new RPoint(pathPoints.get(pnt+1)));
                
              } else {
                // if this point is not good, but you have a path with some points that lead up to this, break that path and start a new one
                if(newPath.size() > 0) {
                  filteredPaths.add(newPath);
                  newPath = new ArrayList<RPoint>();
                }
                newPath.add(new RPoint(pathPoints.get(pnt+1)));
                jaggedCount = 0;
              }
              previousAngle = thisAngle;
            }
            filteredPaths.add(newPath);
          }
        }
      }
    }
    
    return pointsToShape(filteredPaths);
  }
  
  public ArrayList<RPoint> shortenPathBothEnds (ArrayList<RPoint> _path, float _distance) {
    // shorten front of line
    float distanceRemaining = _distance;
    for(int pnt=0; pnt<_path.size(); pnt++) {
      if (pnt+1<_path.size()) {
        float segmentLength = _path.get(pnt).dist(_path.get(pnt+1));
        if(segmentLength > distanceRemaining && abs(distanceRemaining-segmentLength)>.02) { // NOTE: if you see errors with endcaps again (twisted) increase this value and similar one below
          // move the first point closer
          RPath segmentPath = new RPath(_path.get(pnt));
          segmentPath.addLineTo(_path.get(pnt+1));
          float percentToShorten = distanceRemaining / segmentLength;
          RPoint newPoint = segmentPath.getPoint(percentToShorten);
          _path.set(pnt, newPoint);
        } else {
          // remove the point
          _path.remove(pnt);
          pnt--;
        } 
        distanceRemaining-=segmentLength;
        if (distanceRemaining<=0) break;
      } 
    }
    
    // shorten end of line
    distanceRemaining = _distance;
    for(int pnt=_path.size()-1; pnt>=0; pnt--) {
      if (pnt-1>=0) {
        float segmentLength = _path.get(pnt).dist(_path.get(pnt-1));
        if(segmentLength > distanceRemaining && abs(distanceRemaining-segmentLength)>.02) {
          // move the first point closer
          RPath segmentPath = new RPath(_path.get(pnt));
          segmentPath.addLineTo(_path.get(pnt-1));
          float percentToShorten = distanceRemaining / segmentLength;
          RPoint newPoint = segmentPath.getPoint(percentToShorten);
          _path.set(pnt, newPoint);
        } else {
          // remove the point
          _path.remove(pnt);
        } 
        distanceRemaining-=segmentLength;
        if (distanceRemaining<=0) break;
      } 
    }
    
    return _path;
  }
  
  public ArrayList<RPoint> shortenPathEnd (ArrayList<RPoint> _path, float _distance) {
    // shorten end of line
    float distanceRemaining = _distance;
    for(int pnt=_path.size()-1; pnt>=0; pnt--) {
      if (pnt-1>=0) {
        float segmentLength = _path.get(pnt).dist(_path.get(pnt-1));
        if(segmentLength > distanceRemaining && abs(distanceRemaining-segmentLength)>.02) {
          // move the first point closer
          RPath segmentPath = new RPath(_path.get(pnt));
          segmentPath.addLineTo(_path.get(pnt-1));
          float percentToShorten = distanceRemaining / segmentLength;
          RPoint newPoint = segmentPath.getPoint(percentToShorten);
          _path.set(pnt, newPoint);
        } else {
          // remove the point
          _path.remove(pnt);
        } 
        distanceRemaining-=segmentLength;
        if (distanceRemaining<=0) break;
      } 
    }
    
    return _path;
  }
  
  public ArrayList<RPoint> randomizePathStart(ArrayList<RPoint> _path) {
    // shorten end of line
    int startIndex = (int) random(0,_path.size());
    ArrayList<RPoint> newPath = new ArrayList<RPoint>();
    
    newPath.addAll(_path.subList(startIndex, _path.size()-1)); // leave off the last one, since the first one is duplicate
    newPath.addAll(_path.subList(0,startIndex));
    newPath.add(new RPoint(_path.get(startIndex)));
    
    return newPath;
  }
  
  
  public ArrayList<ArrayList<RPoint>> thickenPath(ArrayList<RPoint> _path, int _thickness, float _distance, boolean _roundCap, boolean _asOne){
    if(_roundCap==true) _path = shortenPathBothEnds (_path, _thickness*_distance);
    
    ArrayList<ArrayList<RPoint>> thickenedPaths = new ArrayList<ArrayList<RPoint>>();
    
    if(_path.size()>1) {
    
      ArrayList<RPoint> thickenedPath = new ArrayList<RPoint>();
      
      // add the original line
      for(int pnt=0; pnt<_path.size(); pnt++) {
        thickenedPath.add(new RPoint(_path.get(pnt)));
      }
      
      RPoint centerStart = thickenedPath.get(0);
      RPoint centerEnd = thickenedPath.get(thickenedPath.size()-1);
      
      // create an RPath in order to get tangents
      RPath newRPath = new RPath();
      newRPath = new RPath(_path.get(0));
      for(int pnt=1; pnt<_path.size(); pnt++) {
        newRPath.addLineTo(_path.get(pnt));
      }
      
      if(_asOne==false) {
        thickenedPaths.add(thickenedPath);
        thickenedPath = new ArrayList<RPoint>();
      }
  
      RPoint[] tangents = newRPath.getTangents();
      
      for(int pass=0;pass<_thickness; pass++) {
        // draw pass "below"
        for(int pnt=_path.size()-1; pnt>=0; pnt--) {
          PVector tangentVector;
          if(tangents[pnt].x==_path.get(pnt).x && tangents[pnt].y==_path.get(pnt).y) {
            // if line is straight (based on experience with lines consisting of 2 points), the tangent and point (and handle) are equal
            // so using the geomerative tangent does not work.
            RPoint tangentPoint;
            if(pnt==0) tangentPoint = new RPoint(_path.get(pnt+1));
            else tangentPoint = new RPoint(_path.get(pnt-1));
  
            tangentVector = new PVector(tangentPoint.x-_path.get(pnt).x, tangentPoint.y-_path.get(pnt).y);
            if(pnt==0) tangentVector.rotate(PI);
          } else {
            tangentVector = new PVector(tangents[pnt].x-_path.get(pnt).x, tangents[pnt].y-_path.get(pnt).y);
          }
          tangentVector.rotate(HALF_PI);
          tangentVector.setMag(_distance*(pass+1));
          thickenedPath.add(new RPoint(_path.get(pnt).x+tangentVector.x, _path.get(pnt).y+tangentVector.y));
        }
        
        if(_roundCap==true) {
          RPoint current = thickenedPath.get(thickenedPath.size()-1);
          PVector centerToCurrent = new PVector (current.x-centerStart.x, current.y-centerStart.y);
          thickenedPath.addAll(createArc(centerStart.x, centerStart.y, _distance*(pass+1), centerToCurrent.heading(), centerToCurrent.heading()-PI));
        }
        
        // draw pass "above"
        for(int pnt=0; pnt<_path.size(); pnt++) {
          PVector tangentVector;
          if(tangents[pnt].x==_path.get(pnt).x && tangents[pnt].y==_path.get(pnt).y) {
            // if line is straight (based on experience with lines consisting of 2 points), the tangent and point (and handle) are equal
            // so using the geomerative tangent does not work.
            RPoint tangentPoint;
            if(pnt==0) tangentPoint = new RPoint(_path.get(pnt+1));
            else tangentPoint = new RPoint(_path.get(pnt-1));
  
            tangentVector = new PVector(tangentPoint.x-_path.get(pnt).x, tangentPoint.y-_path.get(pnt).y);
            if(pnt==0) tangentVector.rotate(PI);
          } else {
            tangentVector = new PVector(tangents[pnt].x-_path.get(pnt).x, tangents[pnt].y-_path.get(pnt).y);
          }
          tangentVector.rotate(-HALF_PI);
          tangentVector.setMag(_distance*(pass+1));
          thickenedPath.add(new RPoint(_path.get(pnt).x+tangentVector.x, _path.get(pnt).y+tangentVector.y));
        }
        
        if(_roundCap==true) {
          RPoint current = thickenedPath.get(thickenedPath.size()-1);
          PVector centerToCurrent = new PVector (current.x-centerEnd.x, current.y-centerEnd.y);
          
          thickenedPath.addAll(createArc(centerEnd.x, centerEnd.y, _distance*(pass+1), centerToCurrent.heading(), centerToCurrent.heading()-PI));
          
          thickenedPath = randomizePathStart(thickenedPath); // keep pen-up/down drawing artifacts from lining up.
          shortenPathEnd(thickenedPath, .5f); // minimize pen artifacts (.5 is good number for micron 05 pens)
        }
        
        if(_asOne==false) {
          thickenedPaths.add(thickenedPath);
          thickenedPath = new ArrayList<RPoint>();
        }
      }
      
      if(_asOne==true) {
        thickenedPaths.add(thickenedPath);
      }
    }
    return thickenedPaths;
  }
  
  public RShape thickenLines(RShape _shape, int _thickness, float _distance, boolean _roundCap, boolean _asOne) {
    
    ArrayList<ArrayList<RPoint>> thickenedPaths = new ArrayList<ArrayList<RPoint>> ();
    
    ArrayList<ArrayList<RPoint>> allPathPoints = getPathPoints(_shape);
    
    if (allPathPoints!=null) {
      for(int pth=0; pth<allPathPoints.size(); pth++) {
        ArrayList<RPoint> pathPoints = allPathPoints.get(pth); //allPathPoints[pth];
        
        thickenedPaths.addAll(thickenPath(pathPoints, _thickness, _distance, _roundCap, _asOne));

      }
    }
    
    return pointsToShape(thickenedPaths);
  }  

  private float angleBetween(RPoint p1, RPoint p2) {
    float angle;
    if (p2.y<p1.y) {
      if (p2.x>p1.x) {
        angle = atan((p1.y - p2.y) / (p2.x - p1.x)); 
      } else if (p2.x<p1.x) {
        angle = PI - atan((p1.y - p2.y) / (p1.x - p2.x));
      } else {
        angle = HALF_PI;
      }
    } else if (p2.y>p1.y) {
      if (p2.x>p1.x) {
        angle = TWO_PI -  atan((p2.y - p1.y) / (p2.x - p1.x));
      } else if (p2.x<p1.x) {
        angle =  PI + atan((p2.y - p1.y) / (p1.x - p2.x)); 
      } else {
        angle = TWO_PI - HALF_PI;
      }
    } else {
      if (p2.x>p1.x) {
        angle = 0;
      } else {
        angle = PI;
      }
    }
    return angle;
  }
  
  private ArrayList<ArrayList<RPoint>> getPathPoints(RShape shape){
    ArrayList<ArrayList<RPoint>> pathPoints = new ArrayList<ArrayList<RPoint>> ();
    // NOTE: getPointsInPaths returns four points for a line.
    // NOTE: getPoints the child path also returns four points for a line.
    // NOTE: getHandles returns 3
    // we manually extract points, removing duplicate when two similar points appear in a row
    
    RPoint[][] allPathPoints = shape.getPointsInPaths();
    if(allPathPoints!=null) {
      for(RPoint[] points : allPathPoints) {
        if(points.length>1) {
          ArrayList<RPoint> pointArray = new ArrayList<RPoint>();
          pointArray.add(new RPoint(points[0]));
          for (int i=1; i<points.length; i++) {
            if (points[i-1].x!=points[i].x || points[i-1].y!=points[i].y) {
              pointArray.add(new RPoint(points[i]));
            }
          }
          if(pointArray.size()>1) pathPoints.add(pointArray);
        }
      }
    }
    
    return pathPoints;
  }
  
  private RShape pointsToShape(ArrayList<ArrayList<RPoint>> _paths) {
    RShape output = new RShape();

    for(ArrayList<RPoint> path : _paths) {
      if(path.size()>1) {
        RPath rpath = new RPath(path.get(0));
      
        for(int i=1; i<path.size(); i++) {
          rpath.addLineTo(path.get(i));
        }
        
        RShape newShape = new RShape();
//        newShape.setFill("none");
        newShape.addPath(rpath);
        output.addChild(newShape);
      }
    }
    
    return output;
  }
  
  
  private ArrayList<RPoint> createArc(float x, float y, float r, float start, float end){
    ArrayList<RPoint> path = new ArrayList<RPoint>();
    
    float arcLength = end - start;
    float segmentLength = QUARTER_PI/3;
    if(arcLength<0) segmentLength *= -1;
    int numSegments = abs(ceil(arcLength / segmentLength));
    for (int i = 0; i <= numSegments; i++){
      float thisX = x + r * cos(start+i*segmentLength);
      float thisY = y + r * sin(start+i*segmentLength);
      path.add(new RPoint(thisX, thisY));
    }
    return path;
  }
}
