import kha.Color;
import kha.Framebuffer;

using kha.graphics2.GraphicsExtension;

class Renderer2DMap {
  public function new() {
  }

  public function render(frame:Framebuffer, game:Game):Void {
    final g2 = frame.g2;
    g2.begin();

    // Show map
    var width = game.map[0].length;
    var height = game.map.length;
    var size = Std.int(Math.min(frame.width / width, frame.height / height));
    var dw = (frame.width - size * width) * 0.5;
    var dh = (frame.height - size * height) * 0.5;
    for (y in 0...height) {
      for (x in 0...width) {
        var cell = game.map[y][x];
        if (cell.v != 0) {
          g2.color = Color.fromString(cell.color);
          g2.fillRect(dw + x * size + 1, dh + y * size + 1, size - 2, size - 2);
        }
      }
    }

    // Show hero
    var px = dw + game.posY * size;
    var py = dh + game.posX * size;
    g2.color = Color.fromValue(0xff6050dc); // Blue Majorelle <3
    g2.fillCircle(px, py, size * 0.3);
    g2.color = Color.Yellow;
    g2.drawLine(px, py, px + game.dirY * size * 0.4, py + game.dirX * size * 0.4, 2);

    g2.end();
  }
}