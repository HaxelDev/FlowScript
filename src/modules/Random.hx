package modules;

class Random {
    public static function nextInt(min:Int, max:Int):Int {
        return min + Std.random(max - min + 1);
    }

    public static function random(x:Int):Int {
        return Std.random(x);
    }
}
