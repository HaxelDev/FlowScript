package modules;

class Json {
    public static function parse(jsonStr:String):Dynamic {
        return haxe.Json.parse(jsonStr);
    }

    public static function stringify(obj:Dynamic):String {
        return haxe.Json.stringify(obj);
    }

    public static function isValid(jsonStr:String):Bool {
        try {
            haxe.Json.parse(jsonStr);
            return true;
        } catch (error:Dynamic) {
            return false;
        }
    }
}
