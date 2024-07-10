package modules;

class Random {
    private static var _seed:Int;

    public function new(seed:Int = 0) {
        _seed = seed;
    }

    public static function nextInt(min:Int, max:Int):Int {
        _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
        return min + (_seed % (max - min + 1));
    }
}
