// currently supports sliders and toggles

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
    
    return output;
  }
  
  void saveValues(String path){
    String[] valuesList = split( toString(), "/n");
    saveStrings(path+".txt", valuesList);
  }
}
