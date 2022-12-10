//TODO: some functions in this class(like filterJaggedLines) handle nested shapes, others (like thickenLines) do not; need to come to terms with that to improve reusability

public class GeoUtils {
  RShape diffShape(RShape shape, RShape diffShape){
    return clipShape(shape, diffShape, false);
  }
  
  RShape clipShape(RShape shape, RShape clipShape){
    return clipShape(shape, clipShape, true);
  }
  
  // new way to clip a shape based on other shape, more flexible than previous fill process
  RShape clipShape(RShape shape, RShape clipShape, Boolean inner){
    RShape newShape = new RShape();
    if(shape.countChildren() > 0){
      for(RShape child: shape.children){
        newShape.addChild( clipShape(child, clipShape, inner) );
      }
    }
    if(shape.countPaths() > 0){
      for(RPath path: shape.paths){
        if(clipShape.contains(path) == true && inner == true) {
          // path is entirely inside, add it
          newShape.addChild(new RShape(path));
        } else if(clipShape.contains(path) == false && inner == false && clipShape.getIntersections(new RShape(path)) == null) {
          // path is entirely outside, add it does not intersect
          newShape.addChild(new RShape(path));
        } else if(clipShape.getIntersections(new RShape(path)) == null){
          // no further consideration needed
        } else {
          ArrayList<ArrayList<RPoint>> pointsList = new ArrayList<ArrayList<RPoint>>();
          ArrayList<RPoint> points = new ArrayList<RPoint>();
          RPoint[] pathPoints = shape.getPoints();
          
          Boolean penDown = false;
          for(int i=0; i < shape.getPoints().length-1; i++) {
            if( clipShape.contains(pathPoints[i]) == inner && clipShape.contains(pathPoints[i+1]) == inner) {
              // both points should be included
              if (penDown == false){
                points.add(pathPoints[i]);
                penDown = true;
              }
              points.add(pathPoints[i+1]);
            } else {
              RShape line = RG.getLine(pathPoints[i].x, pathPoints[i].y, pathPoints[i+1].x, pathPoints[i+1].y);
              RPoint[] intersections = line.getIntersections(clipShape);
              if (intersections == null) {
                // ignore
              } else if (intersections.length==1){
                if(clipShape.contains(pathPoints[i])==inner){
                  points.add(pathPoints[i]);
                  points.add(intersections[0]);
                  
                  pointsList.add(points);
                  points = new ArrayList<RPoint>();
                  penDown = false;
                } else {
                  points.add(intersections[0]);
                  points.add(pathPoints[i+1]);
                  penDown = true;
                }
              } else if (intersections.length>1){
                // intersections need to be sorted
                intersections = geoUtils.sortPoints(intersections, pathPoints[i], canvas.width*canvas.height);
                
                // handle point to first intersection
                if (lineIn(pathPoints[i], intersections[0], clipShape) == inner){
                  points.add(pathPoints[i]);
                  points.add(intersections[0]);
                  pointsList.add(points);
                  points = new ArrayList<RPoint>();
                  penDown = false;
                }
                
                for(int j=0; j < intersections.length-1; j++) {
                  if (lineIn(intersections[j], intersections[j+1], clipShape) == inner){
                    points.add(intersections[j]);
                    points.add(intersections[j+1]);
                    penDown = true;
                  } else {
                    pointsList.add(points);
                    points = new ArrayList<RPoint>();
                    penDown = false;
                  }
                }
                
                if (lineIn(intersections[intersections.length-1], pathPoints[i+1], clipShape) == inner){
                  points.add(intersections[intersections.length-1]);
                  points.add(pathPoints[i+1]);
                  penDown = true;
                }
              } 
            }
          }
          
          pointsList.add(points);
          newShape.addChild(geoUtils.pointsToShape(pointsList));
        }
      }
    }
    return newShape;
  }
  
  // add a maskedShape to shape, removing out any lines in the maskedShape that fall inside the shape
  // uses Geormerative boolean operations which generate closed shapes
  public RShape maskShapeFast(RShape shape, RShape maskedShape){
    if(shape.countChildren()==0 && shape.countPaths()==0){
      shape.addChild(maskedShape);
    } else {
      shape.addChild(RG.diff(shape, maskedShape));
    }
    return shape;
  }
  
  // clip the shape using the clipShape
  // uses Geormerative boolean operations which generate closed shapes
  public RShape clipShapeFast(RShape shape, RShape clipShape){
    return RG.intersection(shape, clipShape);
  }
  
  // determine if a line is inside a clipShape based on its midpoint
  Boolean lineIn(RPoint start, RPoint end, RShape clipShape){
    RShape line = RG.getLine(start.x, start.y, end.x, end.y);
    
    return clipShape.contains(line.getPoint(.5));
  }
  
  // older fill, same results, limited use-case, a bit faster than newer, more flexible clip. 
  // creates parallel line fills for a given shape, uses fillClip for the fill
  public RShape fillWithLines(RShape shape, float _spacing, boolean vertical){
    RShape fill = new RShape();
    int minDim = (vertical==true)? (int)shape.getTopLeft().x : (int)shape.getTopLeft().y;
    int maxDim = (vertical==true)? (int)shape.getTopLeft().x + (int)shape.getWidth() : (int)shape.getTopLeft().y + (int)shape.getHeight();
    
    for (float l=minDim-10; l<maxDim+10; l+=_spacing) {  // NOTE: get height is not reliable for all shapes adding some buffer
      RPoint lineBegin = new RPoint(l,(int)shape.getTopLeft().y);
      RShape cuttingLine = RG.getLine(lineBegin.x, lineBegin.y-10, l, (int)shape.getTopLeft().y + shape.getHeight()+10);
      if (vertical==false) {
        lineBegin = new RPoint((int)shape.getTopLeft().x,l);
        cuttingLine = RG.getLine(lineBegin.x-10, lineBegin.y, (int)shape.getTopLeft().x + shape.getWidth()+10, l);
      }
      fill.addChild(cuttingLine);
    }
    return iterativelyClipLines(shape, fill);
  }
  
  // iterates through shape, filling each part will fillClip
  public RShape iterativelyClipLines(RShape _layer, RShape fill) {
    RShape fills = new RShape();
    if (_layer.children!=null) {
      for(RShape child: _layer.children) {
        fills.addChild(iterativelyClipLines(child, fill));
      }
    } else {
      RShape thisfills = clipLines(_layer, fill); 
      if(thisfills.children!=null) {
        for (RShape child: thisfills.children) {
          child.setFill("none");
        }
      }
      fills.addChild(thisfills);
    }
    
    return fills;
  }
  
  // fill shape with another shape, assumes straight lines in the fill
  // This only recognizes holes if the paths are combined as one.
  public RShape clipLines(RShape shape, RShape fill) {
    RShape lines = new RShape();
    if(fill.children != null){
      for (RShape line: fill.children) {  // NOTE: get height is not reliable for all shapes adding some buffer
        if(line.getPoints() != null){
          RPoint firstPoint = line.getPoints()[0];
          RPoint lastPoint = line.getPoints()[line.getPoints().length - 1];
          RPoint[] points = shape.getIntersections(line);
          
          if(points!=null) {
            // these intersection points are not in order. we have to sort them first.
            RPoint[] sortedPoints = sortPoints(points,firstPoint,shape.getWidth()*shape.getHeight());
            
            lines.addChild(RG.getLine(firstPoint.x,firstPoint.y,sortedPoints[0].x,sortedPoints[0].y));
            
            int iterLength = sortedPoints.length;
            for(int p=0; p<iterLength-1; p+=1) {
              if(sortedPoints[p].dist(sortedPoints[p+1])>.5f) {
                lines.addChild(RG.getLine(sortedPoints[p].x,sortedPoints[p].y,sortedPoints[p+1].x,sortedPoints[p+1].y));
              }
            }
            lines.addChild(RG.getLine(sortedPoints[sortedPoints.length - 1].x,sortedPoints[sortedPoints.length - 1].y,lastPoint.x,lastPoint.y));
            
          } else {
            lines.addChild(RG.getLine(firstPoint.x,firstPoint.y,lastPoint.x,lastPoint.y));
          }
        }
      }
      
      lines.setStrokeWeight(.5f);
      lines.setFillAlpha(0);
    }
    
    RShape innerHatches = new RShape();
    if(lines.children != null){
      for (RShape child: lines.children){
        if (shape.contains(child.paths[0].getPoint(.5).x, child.paths[0].getPoint(.5).y)) innerHatches.addChild(child);
      }
    }
    
    return innerHatches;
  }
  
  //Sorts points based on their distance from basepoint, startDistance shoud be a big number
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
  
  // reduces contours based on their proximity to one another
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
  
  // remove short lines from shape if they are shorter than distance parameter
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
  
  // remove shapes from shape if they are smaller than area parameter
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
  
  // join points of the lines if they are closer than distance parameter
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
  
  // remove short lines with sharp turns
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
  
  // crop line from both ends
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
  
  // crop line from end
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
  
  // reorder an arrayList of points from a random start point (so pen is not always starting at same point in concentric lines
  public ArrayList<RPoint> randomizePathStart(ArrayList<RPoint> _path) {
    // shorten end of line
    int startIndex = (int) random(0,_path.size());
    ArrayList<RPoint> newPath = new ArrayList<RPoint>();
    
    newPath.addAll(_path.subList(startIndex, _path.size()-1)); // leave off the last one, since the first one is duplicate
    newPath.addAll(_path.subList(0,startIndex));
    newPath.add(new RPoint(_path.get(startIndex)));
    
    return newPath;
  }
  
  // add paths around each path
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
  
  // Add lines around a path in a given shape
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
  
  // used in several places
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
  
  // used in several places
  private RShape pointsToShape(ArrayList<ArrayList<RPoint>> _paths) {
    RShape output = new RShape();

    for(ArrayList<RPoint> path : _paths) {
      if(path.size()>1) {
        RPath rpath = new RPath(path.get(0));
      
        for(int i=1; i<path.size(); i++) {
          rpath.addLineTo(path.get(i));
        }
        
        RShape newShape = new RShape();
        newShape.addPath(rpath);
        output.addChild(newShape);
      }
    }
    
    return output;
  }
  
  // used in several places
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
