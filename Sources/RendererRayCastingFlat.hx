import kha.Color;
import kha.Framebuffer;

class RendererRayCastingFlat {
  public function new() {
  }

  public function render(frame:Framebuffer, game:Game):Void {
    final g2 = frame.g2;
    g2.begin();

    final w = frame.width;
    final h = frame.height;

    for (x in 0...w) {
      // Calculate ray position and direction
      var cameraX = 2.0 * x / w - 1;
      var rayDirX = game.dirX + game.planeX * cameraX;
      var rayDirY = game.dirY + game.planeY * cameraX;

      // Which box of the map we're in
      var mapX = Std.int(game.posX);
      var mapY = Std.int(game.posY);

      // Length of ray from current position to next x or y-side
      var sideDistX:Float;
      var sideDistY:Float;

      // Length of ray from one x or y-side to next x or y-side
      var deltaDistX = (rayDirY == 0) ? 0 : ((rayDirX == 0) ? 1 : Math.abs(1 / rayDirX));
      var deltaDistY = (rayDirX == 0) ? 0 : ((rayDirY == 0) ? 1 : Math.abs(1 / rayDirY));
      var perpWallDist:Float;

      // What direction to step in x or y-direction (either +1 or -1)
      var stepX:Int;
      var stepY:Int;

      // Was there a wall hit?
      var hit = false;
      // Was a NS (0) or a EW (1) wall hit?
      var side = 0;

      // Calculate step and initial sideDist
      if (rayDirX < 0) {
        stepX = -1;
        sideDistX = (game.posX - mapX) * deltaDistX;
      }
      else {
        stepX = 1;
        sideDistX = (mapX + 1.0 - game.posX) * deltaDistX;
      }
      if (rayDirY < 0) {
        stepY = -1;
        sideDistY = (game.posY - mapY) * deltaDistY;
      }
      else {
        stepY = 1;
        sideDistY = (mapY + 1.0 - game.posY) * deltaDistY;
      }

      // Perform DDA (Digital Differential Analysis)
      while (!hit) {
        // Jump to next map square, OR in x-direction, OR in y-direction
        if (sideDistX < sideDistY) {
          sideDistX += deltaDistX;
          mapX += stepX;
          side = 0;
        }
        else {
          sideDistY += deltaDistY;
          mapY += stepY;
          side = 1;
        }
        // Check if ray has hit a wall
        if (game.map[mapX][mapY].v > 0) hit = true;
      }

      // Calculate distance projected on camera direction (Euclidean distance will give fisheye effect!)
      if (side == 0)  perpWallDist = (mapX - game.posX + (1 - stepX) / 2) / rayDirX;
      else            perpWallDist = (mapY - game.posY + (1 - stepY) / 2) / rayDirY;

      // Calculate height of line to draw on screen
      var lineHeight = Std.int(h / perpWallDist);

      // Calculate lowest and highest pixel to fill in current stripe
      var drawStart = Std.int(-lineHeight / 2 + h / 2);
      if (drawStart < 0) drawStart = 0;
      var drawEnd = Std.int(lineHeight / 2 + h / 2);
      if (drawEnd >= h) drawEnd = h - 1;

      // Choose wall color
      var color:Color = Color.fromString(game.map[mapX][mapY].color);
      // Give x and y sides different brightness
      if (side == 1) {
        var tint = 0.5;
        color = Color.fromBytes(Std.int(color.Rb * tint), Std.int(color.Gb * tint), Std.int(color.Bb * tint));
      }

      // Draw the pixels of the stripe as a vertical line
      g2.color = color;
      g2.drawLine(x, drawStart, x, drawEnd);
    }

    g2.end();
  }
}