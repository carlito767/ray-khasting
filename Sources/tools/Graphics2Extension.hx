package tools;

import kha.FastFloat;
import kha.Image;
import kha.graphics2.Graphics;

import tools.Scaling as S;

class Graphics2Extension {
  public static function drawImageXT(g2:Graphics, img:Image, x:FastFloat, y:FastFloat):Void {
    g2.drawScaledSubImage(img, 0, 0, img.width, img.height, S.X(x), S.Y(y), S.W(img.width), S.H(img.height));
  }

  public static function drawSubImageXT(g2:Graphics, img:Image, x:FastFloat, y:FastFloat, sx:FastFloat, sy:FastFloat, sw:FastFloat, sh:FastFloat):Void {
    g2.drawScaledSubImage(img, sx, sy, sw, sh, S.X(x), S.Y(y), S.W(sw), S.H(sh));
  }

  public static function drawRectXT(g2:Graphics, x:Float, y:Float, width:Float, height:Float, strength:Float = 1.0):Void {
    g2.drawRect(S.X(x), S.Y(y), S.W(width), S.H(height), strength * S.scale);
  }

  public static function fillRectXT(g2:Graphics, x:Float, y:Float, width:Float, height:Float):Void {
    g2.fillRect(S.X(x), S.Y(y), S.W(width), S.H(height));
  }

  public static function drawStringXT(g2:Graphics, text:String, x:Float, y:Float):Void {
    var fontSize = g2.fontSize;
    g2.fontSize = Std.int(fontSize * S.scale);
    g2.drawString(text, S.X(x), S.Y(y));
    g2.fontSize = fontSize;
  }
}