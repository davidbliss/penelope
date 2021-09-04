public class Cell{
  Parameters parameters;
  Drawing grid;
  int cellSize = 100;
  int x;
  int y;
  int z;
  boolean isOccupied;

  Cell(Drawing grid, int x, int y, int z, Parameters parameters){
    this.parameters = parameters;
    this.grid = grid;
    this.x = x;
    this.y = y;
    this.z = z;
  }

  void drawCube(PGraphics graphics){
    preDraw(graphics);
    graphics.strokeWeight(3);
    if (parameters.cp5.getController("drawBoundingBox").getValue()==1)
      graphics.box(int(parameters.cp5.getController("cellSize").getValue()));
    postDraw(graphics);
  }

  ArrayList<PVector> getConnectionVertex(Cell from, Cell to){
    int fromDeltaX = -x + from.x;
    int fromDeltaY = -y + from.y;
    int fromDeltaZ = -z + from.z;

    int toDeltaX = -x + to.x;
    int toDeltaY = -y + to.y;
    int toDeltaZ = -z + to.z;

    float handlePosition = parameters.cp5.getController("tightness").getValue();
    ArrayList<PVector> results = new ArrayList<PVector>();
    float offsetX = -grid.numCellsX/2*cellSize + x*cellSize + cellSize/2;
    float offsetY = -grid.numCellsY/2*cellSize + y*cellSize + cellSize/2;
    float offsetZ = -grid.numCellsZ/2*cellSize + z*cellSize + cellSize/2;
    results.add(new PVector(offsetX+cellSize/2*fromDeltaX,  offsetY+cellSize/2*fromDeltaY,  offsetZ+cellSize/2*fromDeltaZ));
    results.add(new PVector(offsetX+cellSize/2*handlePosition*fromDeltaX,  offsetY+cellSize/2*handlePosition*fromDeltaY,  offsetZ+cellSize/2*handlePosition*fromDeltaZ));
    results.add(new PVector(offsetX+cellSize/2*handlePosition*toDeltaX,    offsetY+cellSize/2*handlePosition*toDeltaY,    offsetZ+cellSize/2*handlePosition*toDeltaZ));
    results.add(new PVector(offsetX+cellSize/2*toDeltaX,    offsetY+cellSize/2*toDeltaY,    offsetZ+cellSize/2*toDeltaZ));

    return results;
  }

  private void preDraw(PGraphics graphics){
    graphics.pushMatrix();
    cellSize = int(parameters.cp5.getController("cellSize").getValue());
    graphics.translate(-grid.numCellsX/2*cellSize + x*cellSize + cellSize/2,
                       -grid.numCellsY/2*cellSize + y*cellSize + cellSize/2,
                       -grid.numCellsZ/2*cellSize + z*cellSize + cellSize/2);
  }

  private void postDraw(PGraphics graphics){
    graphics.popMatrix();
  }
}
