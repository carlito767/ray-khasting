import haxe.ds.Vector;
import kha.Assets;
import kha.Color;
import kha.Framebuffer;

class RendererRayCastingTextured {
  static inline var TEXWIDTH = 32;
  static inline var TEXHEIGHT = 32;

  // Textures
  var walls:Vector<Tile>;

  public function new() {
    var tileset = Assets.images.inca;
    walls = new Vector(8);
    walls[0] = new Tile(tileset, 0 * TEXWIDTH, 0 * TEXHEIGHT, TEXWIDTH, TEXHEIGHT);
    walls[1] = new Tile(tileset, 1 * TEXWIDTH, 0 * TEXHEIGHT, TEXWIDTH, TEXHEIGHT);
    walls[2] = new Tile(tileset, 2 * TEXWIDTH, 0 * TEXHEIGHT, TEXWIDTH, TEXHEIGHT);
    walls[3] = new Tile(tileset, 3 * TEXWIDTH, 0 * TEXHEIGHT, TEXWIDTH, TEXHEIGHT);
    walls[4] = new Tile(tileset, 4 * TEXWIDTH, 0 * TEXHEIGHT, TEXWIDTH, TEXHEIGHT);
    walls[5] = new Tile(tileset, 0 * TEXWIDTH, 1 * TEXHEIGHT, TEXWIDTH, TEXHEIGHT);
    walls[6] = new Tile(tileset, 1 * TEXWIDTH, 1 * TEXHEIGHT, TEXWIDTH, TEXHEIGHT);
    walls[7] = new Tile(tileset, 2 * TEXWIDTH, 1 * TEXHEIGHT, TEXWIDTH, TEXHEIGHT);
  }

  public function render(frame:Framebuffer, game:Game):Void {
    renderCeilingAndFloor(frame, game);
    renderWalls(frame, game);
  }

  function renderCeilingAndFloor(frame:Framebuffer, game:Game):Void {
    final g2 = frame.g2;
    g2.begin();

    final w = frame.width;
    final h = frame.height;
    g2.color = Color.fromBytes(40, 40, 40);
    g2.fillRect(0, 0, w, Math.floor(h * 0.5));
    g2.color = Color.fromBytes(112, 112, 112);
    g2.fillRect(0, Math.floor(h * 0.5), w, Math.ceil(h * 0.5));
    g2.color = Color.White;

    g2.end();
  }

  function renderWalls(frame:Framebuffer, game:Game):Void {
    final g1 = frame.g1;
    g1.begin();

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

      // Texturing calculations
      var texNum = game.map[mapX][mapY].v - 1; //1 subtracted from it so that texture 0 can be used!

      // Calculate value of wallX
      var wallX:Float; // Where exactly the wall was hit
      if (side == 0)  wallX = game.posY + perpWallDist * rayDirY;
      else            wallX = game.posX + perpWallDist * rayDirX;
      wallX -= Math.floor(wallX);

      // x coordinate on the texture
      var texX = Std.int(wallX * TEXWIDTH);
      if (side == 0 && rayDirX > 0) texX = TEXWIDTH - texX - 1;
      if (side == 1 && rayDirY < 0) texX = TEXWIDTH - texX - 1;

      // TODO: an integer-only bresenham or DDA like algorithm could make the texture coordinate stepping faster
      // How much to increase the texture coordinate per screen pixel
      var step = 1.0 * TEXHEIGHT / lineHeight;
      // Starting texture coordinate
      var texPos = (drawStart - h / 2 + lineHeight / 2) * step;
      for (y in drawStart...drawEnd) {
        // Cast the texture coordinate to integer, and mask with (TEXHEIGHT - 1) in case of overflow
        var texY = Std.int(texPos) & (TEXHEIGHT - 1);
        texPos += step;
        var color = walls[texNum].at(texX, texY);
        // Make color darker for y-sides
        if (side == 1) {
          var tint = 0.5;
          color = Color.fromBytes(Std.int(color.Rb * tint), Std.int(color.Gb * tint), Std.int(color.Bb * tint));
        }
        g1.setPixel(x, y, color);
      }
    }

    g1.end();
  }
}