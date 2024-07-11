package modules;

import Math;

class Random {
    public static function nextInt(min:Int, max:Int):Int {
        return min + Std.random(max - min + 1);
    }
}
