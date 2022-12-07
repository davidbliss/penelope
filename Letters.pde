import geomerative.RPath;
import geomerative.RShape;

public class Letters {
  private float w = 10;
  private float h = 2*w;
  private float dec = h-w;
  private float k = w/4;
  private float r = w/3;
  
  public RShape getWords(String words) {
    float x = 0;
    float y = h;
    
    int strokes = 3;
    float distance = .55f;
    

    RShape shape = new RShape();
    
    for (int l = 0; l < words.length(); l++) {
      String letter = words.substring(l,l+1); 
      if(letter.equals(" ")) {
        x += w + r;
      } else {
        shape.addChild(getLetter(letter, x, y, strokes, distance));
        x += getWidth(letter) + r + strokes*distance/2;
      }  
    }
    
    return shape;
    
  }
  
  private RShape getLetter(String letter, float x, float y, int s, float d) {
    RShape shape = new RShape();
    RPath path = new RPath(x,y);
    float sd = s*d;
    float sdp = (s+1)*d;
    float fil = sdp - .5f*d;
    x = x + sd;
    if (letter.equals("a")) {
      path = new RPath(x+w,y+sd);
      path.addLineTo(x+w,y-w/2);
      path = addArcTo(path, x+w/2, y-w/2, w/2, 0, -3*HALF_PI);
      path.addLineTo(x+w-sdp,y);
    } else if (letter.equals("c")) {
      float sx = (x + w/2) + w/2 * cos(-1f/4f*PI);
      float sy = (y - w/2) + w/2 * sin(-1f/4f*PI);
      path = new RPath(sx,sy);
      
      path = addArcTo(path, x+w/2, y-w/2, w/2, -1f/4f*PI,-7f/4f*PI);
    } else if (letter.equals("e")) {
      
      path = new RPath(x+sdp,y-w/2f);
      path.addLineTo(x+w-fil-d,y-w/2f);
      path = addArcTo(path, x+w-fil-d, y-w/2f-fil, fil, HALF_PI, -.2f); 
      path = addArcTo(path, x+w/2, y-w/2, w/2, -1f/6f*PI,-7f/4f*PI);
      
      
    } else if (letter.equals("h")) {
      path = new RPath(x,y-h);
      path.addLineTo(x,y+sd);
      shape.addPath(path);
      path = new RPath(x+.9f*w,y+sd);
      path = addArcTo(path, x+.45f*w, y-.55f*w, .45f*w, 0,-.675f*PI); 
      
    } else if (letter.equals("i")) {
      path = new RPath(x,y-w-sd);
      path.addLineTo(x,y+sd);
      
      shape.addPath(path);
      path = new RPath(x,y-w-2*sd);
      path.addLineTo(x,y-w-2*sd-3.5f); 
      
    } else if (letter.equals("l")) {
      path = new RPath(x,y-h);
      path = addArcTo(path, x+r, y-r, r, PI,HALF_PI);
    } else if (letter.equals("m")) {
      path = new RPath(x,y+sd);
      path.addLineTo(x,y-2f/3f*w);
      path = addArcTo(path, x+1f/3f*w, y-2f/3f*w, 1f/3f*w, -PI+.01f,0);
      path.addLineTo(x+2f/3f*w,y+sd);
      shape.addPath(path);

      path = new RPath(x+4f/3f*w,y+sd);
      path.addLineTo(x+4f/3f*w,y-2f/3f*w);
      path = addArcTo(path, x+w, y-2f/3f*w, 1f/3f*w, -0.1f, -.72f*PI); // TODO: might be cool to clip this 
      
    } else if (letter.equals("n")) {
      path = new RPath(x,y+sd);
      path.addLineTo(x,y-.6f*w);
      path = addArcTo(path, x+.4f*w, y-.6f*w, .4f*w, -PI,0);
      path.addLineTo(x+.8f*w,y+sd);
      
    } else if (letter.equals("o")) {
      float baseRadius = w;// - (s*d);
      shape.addChild(RShape.createCircle(x+w/2, y-w/2, baseRadius));
      for (int i=1; i<=s; i++) {
        shape.addChild(RShape.createCircle(x+w/2, y-w/2, baseRadius-(2*i*d)));
        shape.addChild(RShape.createCircle(x+w/2, y-w/2, baseRadius+(2*i*d)));
      }
    } else if (letter.equals("p")) {
      path = new RPath(x+sd+d,y);
      path = addArcTo(path, x+w/2, y-w/2, w/2, HALF_PI, -2*HALF_PI);
      path.addLineTo(x,y+dec);
    } else if (letter.equals("r")) {
      path = new RPath(x,y+sd);
      path.addLineTo(x,y-.6f*w);
      path = addArcTo(path, x+.4f*w, y-.6f*w, .4f*w, -PI+.01f,0);
      
    } else if (letter.equals("s")) {
      float sx = (x + .33f*w) + .25f*w * cos(-.1f*PI);
      float sy = (y - .75f*w) + .25f*w * sin(-.1f*PI);
      path = new RPath(sx,sy);
      
      path = addArcTo(path, x+.33f*w, y-.75f*w, w/4, -.05f*PI, -HALF_PI);
      path = addArcTo(path, x+.25f*w, y-.75f*w, w/4, -HALF_PI, -3*HALF_PI);
      
      path = addArcTo(path, x+.33f*w, y-.25f*w, w/4, - HALF_PI, HALF_PI);
      path = addArcTo(path, x+.25f*w, y-.25f*w, w/4, HALF_PI, 1.05f*PI);
      
    } else if (letter.equals("t")) {
//      x = x +.35f*w;
      path = new RPath(x,y-w-2*sd-3.5f);
      path = addArcTo(path, x+r, y-r, r, PI,HALF_PI);
      shape.addPath(path);
      
      path = new RPath(x+sdp,y-w);
      path.addLineTo(x+sdp+4f,y-w); 
      
    } else if (letter.equals("y")) {
      
      path = new RPath(x,y+dec-w/2-sd);
      path = addArcTo(path, x+.45f*w, y+dec-.55f*w-sd, .45f*w, PI, 0);
      path.addLineTo(x+.9f*w,y-w-sd);
      shape.addPath(path);

      path = new RPath(x,y-w-sd);
      path.addLineTo(x,y-.5f*w);
      path = addArcTo(path, x+.5f*w, y-.5f*w, .5f*w, PI, .375f*PI);
    }
    
    shape.addPath(path);
    if (!letter.equals("o")) shape = geoUtils.thickenLines(shape, s, d, true, false);
    
    return shape;
  }
  
  private float getWidth(String letter) {
    float adjustment = 1.1f;
    
    if (letter.equals("c")) {
      return .8f*w*adjustment;
    } else if (letter.equals("e")) {
      return w*.95f*adjustment;
    } else if (letter.equals("h")) {
      return w*.95f*adjustment;
    } else if (letter.equals("i")) {
      return w*.1f*adjustment;
    } else if (letter.equals("l")) {
      return w/10*adjustment;
    } else if (letter.equals("m")) {
      return w*1.32f*adjustment;
    } else if (letter.equals("r")) {
      return w*.8f*adjustment;
    } else if (letter.equals("s")) {
      return w*.65f*adjustment;
    } else if (letter.equals("t")) {
      return w*.45f*adjustment;
    } else if (letter.equals("y")) {
      return w*.9f*adjustment;
    } 
    
    return w*adjustment;
  }
  
  private RPath addArcTo(RPath path, float x, float y, float r, float start, float end){
    float arcLength = end - start;
    float segmentLength = QUARTER_PI/6f;
  
    int numSegments = abs(ceil(arcLength / segmentLength));
    if(arcLength<0) segmentLength *= -1;
    
    segmentLength = arcLength / numSegments;

    for (int i = 0; i <= numSegments; i++){
      float thisX = x + r * cos(start+i*segmentLength);
      float thisY = y + r * sin(start+i*segmentLength);
      path.addLineTo(thisX, thisY);
    }
    return path;
  }
}
