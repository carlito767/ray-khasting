import kha.Assets;
import kha.Color;
import kha.Framebuffer;
import kha.Scheduler;
import kha.input.Keyboard;
import kha.input.KeyCode;

import assets.World;

class Game {
  // Map
  public var map:Array<Array<Cell>>;

  // Player position
  public var posX:Float;
  public var posY:Float;

  // Direction vector
  public var dirX:Float;
  public var dirY:Float;

  // Camera plane
  public var planeX:Float;
  public var planeY:Float;

  // Sprites
  public var sprites:Array<Sprite>;

  // Renderers
  var renderer2DMap:Renderer2DMap;
  var rendererRayCastingFlat:RendererRayCastingFlat;
  var rendererRayCastingTextured:RendererRayCastingTextured;

  // Commands
  var up:Bool;
  var down:Bool;
  var left:Bool;
  var right:Bool;

  var toNextLevel:Bool;

  var showMap:Bool;
  var showTextures:Bool;

  var showHelp:Bool;

  // World
  var world:World;
  var levelIndex:Int;

  // FPS
  var previousFrameTime = 0.0;
  var currentFrameTime = 0.0;

  public function new() {
    // Initialize world
    world = new World();
    loadLevel(0);

    // Initialize renderers
    renderer2DMap = new Renderer2DMap();
    rendererRayCastingFlat = new RendererRayCastingFlat();
    rendererRayCastingTextured = new RendererRayCastingTextured();

    showTextures = true;

    // Initialize keyboard
    var keyboard = Keyboard.get();
    if (keyboard != null) {
      keyboard.notify(onKeyDown, onKeyUp, null);
    }
  }

  //
  // Level
  //

  function loadLevel(idx:Int):Void {
    levelIndex = idx;
    var level = world.levels[idx];
    // Map
    var layer = level.l_Map;
    map = [for (y in 0...layer.cHei) [for (x in 0...layer.cWid) {
      v: layer.getInt(x, y),
      color: layer.getColorHex(x, y),
    }]];
    // Hero
    var hero = level.l_Entities.all_Hero[0];
    posX = hero.cy + hero.pivotY;
    posY = hero.cx + hero.pivotX;
    dirX = -1.0;
    dirY = 0.0;
    // Camera
    planeX = 0.0;
    planeY = 0.66;
    // Sprites
    sprites = [];
    for (maki in level.l_Entities.all_Maki) {
      sprites.push({
        x:maki.cy + maki.pivotY,
        y:maki.cx + maki.pivotX,
        tex:maki.f_tex,
      });
    }
  }

  function loadNextLevel():Void {
    var idx = (levelIndex < world.levels.length - 1) ? levelIndex + 1 : 0;
    loadLevel(idx);
  }

  //
  // Keyboard
  //

  function onKeyDown(key:KeyCode):Void {
    switch (key) {
      case Up: up = true;
      case Down: down = true;
      case Left: left = true;
      case Right: right = true;
      case L: toNextLevel = true;
      case M: showMap = !showMap;
      case T: showTextures = !showTextures;
      case H: showHelp = !showHelp;
      default:
    }
  }

  function onKeyUp(key:KeyCode):Void {
    switch (key) {
      case Up: up = false;
      case Down: down = false;
      case Left: left = false;
      case Right: right = false;
      default:
    }
  }

  //
  // Game loop
  //

  @:allow(Main.main)
  function update():Void {
    // FPS
    previousFrameTime = currentFrameTime;
    currentFrameTime = Scheduler.realTime();

    // Next level?
    if (toNextLevel) {
      toNextLevel = false;
      loadNextLevel();
      return;
    }

    // Speed modifiers
    final frameTime = currentFrameTime - previousFrameTime;
    var moveSpeed = frameTime * 5.0;  // the constant value is in squares/second
    var rotSpeed = frameTime * 3.0;   // the constant value is in radians/second

    // Move forward if no wall in front of you
    if (up) {
      if (map[Std.int(posX + dirX * moveSpeed)][Std.int(posY)].v == 0) posX += dirX * moveSpeed;
      if (map[Std.int(posX)][Std.int(posY + dirY * moveSpeed)].v == 0) posY += dirY * moveSpeed;
    }
    // Move backwards if no wall behind you
    if (down) {
      if (map[Std.int(posX - dirX * moveSpeed)][Std.int(posY)].v == 0) posX -= dirX * moveSpeed;
      if (map[Std.int(posX)][Std.int(posY - dirY * moveSpeed)].v == 0) posY -= dirY * moveSpeed;
    }
    // Rotate to the left
    if (left) {
      // Both camera direction and camera plane must be rotated
      var oldDirX = dirX;
      dirX = dirX * Math.cos(rotSpeed) - dirY * Math.sin(rotSpeed);
      dirY = oldDirX * Math.sin(rotSpeed) + dirY * Math.cos(rotSpeed);
      var oldPlaneX = planeX;
      planeX = planeX * Math.cos(rotSpeed) - planeY * Math.sin(rotSpeed);
      planeY = oldPlaneX * Math.sin(rotSpeed) + planeY * Math.cos(rotSpeed);
    }
    // Rotate to the right
    if (right) {
      // Both camera direction and camera plane must be rotated
      var oldDirX = dirX;
      dirX = dirX * Math.cos(-rotSpeed) - dirY * Math.sin(-rotSpeed);
      dirY = oldDirX * Math.sin(-rotSpeed) + dirY * Math.cos(-rotSpeed);
      var oldPlaneX = planeX;
      planeX = planeX * Math.cos(-rotSpeed) - planeY * Math.sin(-rotSpeed);
      planeY = oldPlaneX * Math.sin(-rotSpeed) + planeY * Math.cos(-rotSpeed);
    }
  }

  @:allow(Main.main)
  function render(frame:Framebuffer):Void {
    // Render level
    if (showMap) {
      renderer2DMap.render(frame, this);
    }
    else if (showTextures) {
      rendererRayCastingTextured.render(frame, this);
    }
    else {
      rendererRayCastingFlat.render(frame, this);
    }

    // Show help
    final g2 = frame.g2;
    g2.begin(false);

    g2.color = Color.White;
    g2.font = Assets.fonts.OpenSans;
    g2.fontSize = 30;
    if (showHelp) {
      var padding = g2.fontSize + 5;
      g2.drawString('L: next level', 0, 0);
      g2.drawString('M: toggle 2D map', 0, padding);
      g2.drawString('T: toggle textures', 0, padding * 2);
    }
    else {
      g2.drawString('H: help', 0, 0);
    }

    g2.end();
  }
}