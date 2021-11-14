import kha.Color;
import kha.Framebuffer;
import kha.System;

import assets.World;
import tools.Scaling;
using tools.Graphics2Extension;

class Game {
  // Resolution
  final WIDTH = System.windowWidth();
  final HEIGHT = System.windowHeight();

  // World
  var world:World;
  var level:World_Level;

  @:allow(Main.main)
  function new() {
    world = new World();
    level = world.all_levels.Level_0;
  }

  //
  // Game loop
  //

  @:allow(Main.main)
  function update():Void {
  }

  @:allow(Main.main)
  function render(frame:Framebuffer):Void {
    Scaling.set(WIDTH, HEIGHT, frame.width, frame.height);

    final g2 = frame.g2;
    g2.begin();

    var bgColor = Color.fromValue(level.bgColor);
    bgColor.A = 1.0;
    g2.color = bgColor;
    g2.fillRectXT(0, 0, WIDTH, HEIGHT);

    var layer = level.l_Map;
    var gridW = layer.gridSize * (WIDTH / level.pxWid);
    var gridH = layer.gridSize * (HEIGHT / level.pxHei);
    for (y in 0...layer.cHei) {
      for (x in 0...layer.cWid) {
        var v = layer.getInt(x, y);
        if (v != 0) {
          g2.color = Color.fromString(layer.getColorHex(x, y));
          g2.fillRectXT(x * gridW, y * gridH, gridW, gridH);
        }
      }
    }

    g2.end();
  }
}