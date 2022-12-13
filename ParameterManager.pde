// currently supports sliders, ranges, and toggles

public class ParameterManager {
  ControlP5 cp5;

  ParameterManager(ControlP5 _cp5) {
    cp5=_cp5;
  }
  
  void randomize(){
    List<Slider> sliders = cp5.getAll(Slider.class);
    for(Slider slider:sliders) {
      slider.shuffle();
    }
    
    List<Toggle> toggles = cp5.getAll(Toggle.class);
    for(Toggle toggle:toggles) {
      toggle.setValue(int(random(0,2)));
    }
    
    List<Range> ranges = cp5.getAll(Range.class);
    for(Range range:ranges) {
      float v1 = random(range.getMin(),range.getMax());
      float v2 = random(range.getMin(),range.getMax());
      
      range.setLowValue(Math.min(v1, v2));
      range.setHighValue(Math.max(v1, v2));
    }
  }
  
  String toString(){
    String output = "";
    List<Slider> sliders = cp5.getAll(Slider.class);
    for(Slider slider:sliders) {
      output += "slider, "+slider.getName()+": " +slider.getValue() +"\n";
    }
    
    List<Toggle> toggles = cp5.getAll(Toggle.class);
    for(Toggle toggle:toggles) {
      output += "toggle, "+toggle.getName()+": " +toggle.getValue() +"\n";
    }
    
    List<Range> ranges = cp5.getAll(Range.class);
    for(Range range:ranges) {
      output += "range, "+range.getLowValue()+", "+range.getHighValue();
    }
    
    return output;
  }
}
