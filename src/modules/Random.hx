package modules;

import Math;

class Random {
    private static var _seed:Float = Math.random();

    public static function nextInt(min:Int, max:Int):Int {
        _seed = (_seed * 1103515245.0 + 12345.0) % 0x7fffffff;
        return min + Math.floor(_seed / 0x7fffffff * (max - min + 1));
    }
}
