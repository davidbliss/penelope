
public class ColorManager{
  float numColors = 4;
  
  color[] colors = {
                    #FF2F0A,
                    #FF890A,
                    #FFE70A,
                   };
                    
  color ranColor() {
    return colors[int(random(0,numColors))];
  }
}
