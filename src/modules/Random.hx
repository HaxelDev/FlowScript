package modules;

class Random {
    public static function nextInt(min:Int, max:Int):Int {
        return min + Std.random(max - min + 1);
    }

    public static function choice<T>(list:Array<T>):T {
        if (list.length == 0) {
            Flow.error.report("Cannot choose from an empty list.");
        }
        var index:Int = nextInt(0, list.length - 1);
        return list[index];
    }
}
