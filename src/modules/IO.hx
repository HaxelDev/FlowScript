package modules;

using StringTools;

class IO {
    public static function readLine(value:String):String {
        Sys.stdout().writeString(value);
        return Sys.stdin().readLine().trim();
    }

    public static function print(value:String):Void {
        Sys.stdout().writeString(value);
    }

    public static function println(value:String):Void {
        Sys.stdout().writeString(value + "\n");
    }

    public static function writeByte(value:Int):Void {
        if (value < 0 || value > 255) {
            Flow.error.report("Invalid byte value: " + value);
        }
        Sys.stdout().writeByte(value);
    }
}
