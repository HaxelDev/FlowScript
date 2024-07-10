package modules;

using StringTools;

class IO {
    public static function readLine():String {
        Sys.stdout().writeString(">>> ");
        return Sys.stdin().readLine().trim();
    }

    public static function print(value:String):Void {
        Sys.stdout().writeString(value);
    }

    public static function println(value:String):Void {
        Sys.stdout().writeString(value + "\n");
    }
}
