package tools;

class Scaling {
  public static inline function X(x:Float):Float return ox + x * scale;
  public static inline function Y(y:Float):Float return oy + y * scale;
  public static inline function W(w:Float):Float return w * scale;
  public static inline function H(h:Float):Float return h * scale;

  public static var scale(default,null):Float = 1.0;
  public static var ox(default,null):Float = 0.0;
  public static var oy(default,null):Float = 0.0;

  public static inline function set(gameWidth:Int, gameHeight:Int, screenWidth:Int, screenHeight:Int):Void {
    var gameAspectRatio = gameWidth / gameHeight;
    var screenAspectRatio = screenWidth / screenHeight;
    var scaleHorizontal = screenWidth / gameWidth;
    var scaleVertical = screenHeight / gameHeight;

    scale = (gameAspectRatio > screenAspectRatio) ? scaleHorizontal : scaleVertical;
    ox = (screenWidth - (gameWidth * scale)) * 0.5;
    oy = (screenHeight - (gameHeight * scale)) * 0.5;
  }
}