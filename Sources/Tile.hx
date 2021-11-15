import kha.Color;
import kha.Image;

class Tile {
  var source:Image;
  var x:Int;
  var y:Int;
  var w:Int;
  var h:Int;

  public function new(source:Image, x:Int, y:Int, w:Int, h:Int) {
    this.source = source;
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }

  public function at(dx:Int, dy:Int):Color {
    return source.at(x + dx, y + dy);
  }
}