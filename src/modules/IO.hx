package modules;

class IO {
    public static function print(value:Dynamic):Void {
        Sys.println(value);
    }

    public static function readline():String {
        return Sys.stdin().readLine();
    }
}
