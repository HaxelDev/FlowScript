package modules;

class Math {
    public static function abs(x:Float):Float {
        return x < 0 ? -x : x;
    }

    public static function max(a:Float, b:Float):Float {
        return a > b ? a : b;
    }

    public static function min(a:Float, b:Float):Float {
        return a < b ? a : b;
    }

    public static function pow(base:Float, exponent:Float):Float {
        return Math.pow(base, exponent);
    }

    public static function sqrt(x:Float):Float {
        return Math.sqrt(x);
    }
}
