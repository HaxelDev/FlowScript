package modules;

import modules.json.Lexer;
import modules.json.Parser;

class Json {
    public static function parse(jsonString:String):Dynamic {
        try {
            var lexer = new Lexer(jsonString);
            var parser = new Parser(lexer);
            return parser.parse();
        } catch (e:Dynamic) {
            Flow.error.report("Parsing error: " + e.toString());
            return null;
        }
    }

    public static function stringify(data:Dynamic):String {
        return stringifyValue(data);
    }

    public static function isValid(jsonString:String):Bool {
        try {
            var lexer = new Lexer(jsonString);
            new Parser(lexer).parse();
            return true;
        } catch (error:Dynamic) {
            return false;
        }
    }

    private static function stringifyValue(value:Dynamic):String {
        switch (Type.typeof(value)) {
            case TNull:
                return "null";
            case TInt, TFloat:
                return Std.string(value);
            case TBool:
                return value ? "true" : "false";
            case TClass(String):
                return quoteString(value);
            case TClass(Array):
                return "[" + value.map(stringifyValue).join(",") + "]";
            case TObject:
                var objFields:Array<String> = [];
                for (field in Reflect.fields(value)) {
                    var key:String = field;
                    var fieldValue:Dynamic = Reflect.field(value, field);
                    objFields.push(quoteString(key) + ":" + stringifyValue(fieldValue));
                }
                return "{" + objFields.join(",") + "}";
            default:
                return "null";
        }
    }

    private static function quoteString(s:String):String {
        return "\"" + StringTools.replace(s, "\"", "\\\"") + "\"";
    }
}
