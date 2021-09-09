// For convinience, all drawing things are consolidated here

public class Drawing{
  Parameters parameters;

  Cell [][][] cells;
  ArrayList<ArrayList<Cell>> chains;
  public int numCellsX;
  public int numCellsY;
  public int numCellsZ;

  Drawing(Parameters parameters){
    this.parameters = parameters;
    init();
  }

  public void init(){

  }

  public void draw(OffscreenCanvas canvas){
    canvas.graphics.beginDraw();
    canvas.graphics.stroke(color(0), 255);
    canvas.graphics.strokeWeight(3);
    canvas.graphics.strokeCap(ROUND);
    canvas.graphics.noFill();
    
    //canvas.graphics.rect(offscreenCanvasMargin,offscreenCanvasMargin,canvas.graphics.width-(2*offscreenCanvasMargin),canvas.graphics.height-(2*offscreenCanvasMargin));

    // draw a rectangle
    // TODO: account for cropping rectangle and other 2d shapes?
    // canvas.graphics.rect(100,100,200,200);

    // draw a 3d bezier
    //canvas.draw3dBezier(new PVector(-1000, 0, 0),new PVector(10, -10, 10),new PVector(90, -90, 90),new PVector(100, 100, 100));
    //canvas.draw3dBezier(new PVector(100,500,100),new PVector(90, -90, 90),new PVector(10, -10, 10),new PVector(-1000, 500, 100));
    //drawChains(canvas);

    
    //canvas.drawBox(18);
    
    float boxSize = 162.5;
    int numCols = 6;
    int numRows = 9;
    
    canvas.graphics.stroke(color(255,0,0));
    
    canvas.offscreen3d.translate(-boxSize*numCols/2, -boxSize*(numRows/2+2.2), -boxSize*numCols/2);
    
    //canvas.offscreen3d.pushMatrix();
    for (int r = 0; r < numRows; r++){
      canvas.offscreen3d.translate(0, boxSize, boxSize);
      for (int c = 0; c < numCols; c++){
        
        canvas.drawBoxTile(boxSize, r==0, c==0, c==numCols-1, r==numRows-1, r%2==1);
        
        canvas.offscreen3d.translate(boxSize, 0, boxSize);
      }
      canvas.offscreen3d.translate(-boxSize*(numCols+((r+1)%2)), 0, -boxSize*(numCols+((r+1)%2)));
    }
      
    //canvas.drawBox(1200);
    //canvas.drawCroppedLine(new PVector(0,200), new PVector(1600,300));

    canvas.graphics.endDraw();
  }

  public Cell getRandomCell(){
    PVector loc = getRandomLocation();
    return cells[int(loc.x)][int(loc.y)][int(loc.z)];
  }

  private Cell getRandomNeighboorCell(Cell cell){
    ArrayList<Cell> options = getAvailableNeighboors(cell);
    if (options.size()==0) return null;
    return options.get(floor(random(options.size())));
  }

  private ArrayList<Cell> getAvailableNeighboors(Cell cell){
    ArrayList<Cell> options = new ArrayList<Cell>();
    if (cell.x>0)
      if (cells[cell.x-1][cell.y][cell.z].isOccupied==false ) options.add(cells[cell.x-1][cell.y][cell.z]);
    if (cell.x<numCellsX-1)
      if (cells[cell.x+1][cell.y][cell.z].isOccupied==false ) options.add(cells[cell.x+1][cell.y][cell.z]);

    if (cell.y>0)
      if (cells[cell.x][cell.y-1][cell.z].isOccupied==false ) options.add(cells[cell.x][cell.y-1][cell.z]);
    if (cell.y<numCellsY-1)
      if (cells[cell.x][cell.y+1][cell.z].isOccupied==false ) options.add(cells[cell.x][cell.y+1][cell.z]);

    if (cell.z>0)
      if (cells[cell.x][cell.y][cell.z-1].isOccupied==false ) options.add(cells[cell.x][cell.y][cell.z-1]);
    if (cell.z<numCellsZ-1)
      if (cells[cell.x][cell.y][cell.z+1].isOccupied==false ) options.add(cells[cell.x][cell.y][cell.z+1]);

    return options;
  }

  private PVector getRandomLocation(){
    PVector loc = new PVector(floor(random(numCellsX)), floor(random(numCellsY)), floor(random(numCellsZ)));
    return loc;
  }

  public void makeChains(){
    numCellsX = int(parameters.cp5.getController("numCellsX").getValue());
    numCellsY = int(parameters.cp5.getController("numCellsY").getValue());
    numCellsZ = int(parameters.cp5.getController("numCellsZ").getValue());

    cells = new Cell[numCellsX][numCellsY][numCellsZ];

    for (int x = 0; x < numCellsX; x++){
      for (int y = 0; y < numCellsY; y++){
        for (int z = 0; z < numCellsZ; z++){
          cells[x][y][z] = new Cell(this, x, y, z, parameters);
        }
      }
    }

    chains = new ArrayList<ArrayList<Cell>>();

    for (int i=0; i<int(parameters.cp5.getController("numberChains").getValue()); i++){
      Cell previous = getRandomCell();
      ArrayList<Cell>chain=new ArrayList<Cell>();
      chain.add(previous);

      for (int ii = 0; ii<int(parameters.cp5.getController("lengthChains").getValue()); ii++){
        Cell next = getRandomNeighboorCell(previous);
        if (next!=null) {
          next.isOccupied = true;
          chain.add(next);
          previous = next;
        }
      }

      chains.add(chain);
    }
  }

  public void drawChains(OffscreenCanvas canvas){
    // draw a bunch of curves
    for (int ii = 0; ii<chains.size(); ii++){
      ArrayList<Cell>chain = chains.get(ii);

      for (int i = 1; i<chain.size()-1; i++){
        ArrayList<PVector> pvList= chain.get(i).getConnectionVertex(chain.get(i-1), chain.get(i+1));
        canvas.draw3dBezier(pvList.get(0),pvList.get(1),pvList.get(2),pvList.get(3));
      }
    }
  }
}
