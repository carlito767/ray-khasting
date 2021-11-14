import haxe.macro.Compiler;
import kha.Assets;
import kha.Scheduler;
import kha.System;

class Main {
  public static function main() {
    System.start({title:title(), width:800, height:600}, (_)->{
      Assets.loadEverything(()->{
        var game = new Game();
        Scheduler.addTimeTask(game.update, 0, 1 / 60);
        System.notifyOnFrames((frames)->{ game.render(frames[0]); });
      });
    });
  }

  static function title():String {
    return Compiler.getDefine('kha_project_name');
  }
}