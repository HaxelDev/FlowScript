package modules;

class Math {
    public static function getPI():Float {
        return 3.141592653589793;
    }

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

    public static function sin(x:Float):Float {
        return Math.sin(x);
    }

    public static function cos(x:Float):Float {
        return Math.cos(x);
    }

    public static function tan(x:Float):Float {
        return Math.tan(x);
    }

    public static function asin(x:Float):Float {
        return Math.asin(x);
    }

    public static function acos(x:Float):Float {
        return Math.acos(x);
    }

    public static function atan(x:Float):Float {
        return Math.atan(x);
    }
}
