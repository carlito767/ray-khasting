import haxe.ds.Vector;
import kha.Assets;
import kha.Color;
import kha.Framebuffer;

typedef ZBuffer = Vector<Float>;

typedef ZSprite = {
  index:Int,
  distance:Float,
}

class RendererRayCastingTextured {
  static inline var TEXWIDTH = 32;
  static inline var TEXHEIGHT = 32;

  static inline var SPRWIDTH = 16;
  static inline var SPRHEIGHT = 16;

  // Textures
  var walls:Vector<Tile>;
  var sprites:Vector<Tile>;

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

    tileset = Assets.images.food;
    sprites = new Vector(2);
    sprites[0] = new Tile(tileset, 6 * SPRWIDTH, 0 * SPRHEIGHT, SPRWIDTH, SPRHEIGHT); // Maki 1
    sprites[1] = new Tile(tileset, 7 * SPRWIDTH, 0 * SPRHEIGHT, SPRWIDTH, SPRHEIGHT); // Maki 2
  }

  public function render(frame:Framebuffer, game:Game):Void {
    renderCeilingAndFloor(frame, game);
    var zBuffer = renderWalls(frame, game);
    if (game.sprites.length > 0) {
      renderSprites(frame, game, zBuffer);
    }
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

  function renderWalls(frame:Framebuffer, game:Game):ZBuffer {
    final g1 = frame.g1;
    g1.begin();

    final w = frame.width;
    final h = frame.height;

    // 1D Z buffer
    var zBuffer = new ZBuffer(frame.height);

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

      // Set the Z buffer for the sprite casting
      zBuffer[x] = perpWallDist;
    }

    g1.end();

    return zBuffer;
  }

  function renderSprites(frame:Framebuffer, game:Game, zBuffer:ZBuffer):Void {
    final g1 = frame.g1;
    g1.begin();

    final w = frame.width;
    final h = frame.height;

    // Sort sprites from far to close
    var n = game.sprites.length;
    var zSprites = new Vector<ZSprite>(n);
    for (i in 0...n) {
      zSprites[i] = {
        index: i,
        distance: ((game.posX - game.sprites[i].x) * (game.posX - game.sprites[i].x) + (game.posY - game.sprites[i].y) * (game.posY - game.sprites[i].y)),
      };
    }
    zSprites.sort(function(a:ZSprite, b:ZSprite):Int {
      if (a.distance == b.distance) return 0;
      return (a.distance > b.distance) ? -1 : 1;
    });

    final scaleX = SPRWIDTH / TEXWIDTH;
    final scaleY = SPRHEIGHT / TEXHEIGHT;

    // After sorting the sprites, do the projection and draw them
    for (i in 0...n) {
      // Translate sprite position to relative to camera
      var spriteX = game.sprites[zSprites[i].index].x - game.posX;
      var spriteY = game.sprites[zSprites[i].index].y - game.posY;

      // Transform sprite with the inverse camera matrix
      // [ planeX   dirX ] -1                                       [ dirY      -dirX ]
      // [               ]       =  1/(planeX*dirY-dirX*planeY) *   [                 ]
      // [ planeY   dirY ]                                          [ -planeY  planeX ]

      var invDet = 1.0 / (game.planeX * game.dirY - game.dirX * game.planeY); // Required for correct matrix multiplication

      var transformX = invDet * (game.dirY * spriteX - game.dirX * spriteY);
      var transformY = invDet * (-game.planeY * spriteX + game.planeX * spriteY); // This is actually the depth inside the screen, that what Z is in 3D

      var spriteScreenX = Std.int((w / 2) * (1 + transformX / transformY));

      // Calculate height of the sprite on screen
      var spriteHeight = Math.abs(Std.int(h / (transformY))); // Using 'transformY' instead of the real distance prevents fisheye
      spriteHeight *= scaleY;
      // Calculate lowest and highest pixel to fill in current stripe
      var drawStartY = Std.int(-spriteHeight / 2 + h / 2);
      if (drawStartY < 0) drawStartY = 0;
      var drawEndY = Std.int(spriteHeight / 2 + h / 2);
      if (drawEndY >= h) drawEndY = h - 1;

      // Calculate width of the sprite
      var spriteWidth = Math.abs(Std.int(h / (transformY)));
      spriteWidth *= scaleX;
      var drawStartX = Std.int(-spriteWidth / 2 + spriteScreenX);
      if (drawStartX < 0) drawStartX = 0;
      var drawEndX = Std.int(spriteWidth / 2 + spriteScreenX);
      if (drawEndX >= w) drawEndX = w - 1;

      // Loop through every vertical stripe of the sprite on screen
      for (stripe in drawStartX...drawEndX) {
        var texX = Std.int(256 * (stripe - (-spriteWidth / 2 + spriteScreenX)) * (SPRWIDTH / spriteWidth) / 256);
        // The conditions in the if are:
        // 1) it's in front of camera plane so you don't see things behind you
        // 2) it's on the screen (left)
        // 3) it's on the screen (right)
        // 4) ZBuffer, with perpendicular distance
        if (transformY > 0 && stripe > 0 && stripe < w && transformY < zBuffer[stripe]) {
          for (y in drawStartY...drawEndY) {
            // For every pixel of the current stripe
            var d = Std.int(y * 256 - h * 128 + spriteHeight * 128); // 256 and 128 factors to avoid floats
            var texY = Std.int(((d * SPRHEIGHT) / spriteHeight) / 256);
            var sprite = sprites[game.sprites[zSprites[i].index].tex];
            var color = sprite.at(texX, texY);
            g1.setPixel(stripe, y, color);
          }
        }
      }
    }

    g1.end();
  }
}