package modules;

import hscript.Parser;
import hscript.Interp;

class HX {
    private static var interp:Interp = new Interp();

    public static function eval(code:String):Dynamic {
        var parser = new Parser();
        var ast = parser.parseString(code);

        var cls:Map<String, Dynamic> = [
            "Math"    => Math,
            "Std"     => Std,
            "String"  => String,
            "Array"   => Array,
            "Date"    => Date,
            "Reflect" => Reflect,
            "StringTools" => StringTools,
            "Int"     => Int,
            "Float"   => Float,
            "Bool"    => Bool
        ];

        #if sys cls["Sys"] = Sys; #end
        for (name => cl in cls) {
            interp.variables.set(name, cl);
        }

        parser.allowTypes = true;
        parser.allowJSON = true;
        parser.allowMetadata = true;

		interp.allowStaticVariables = true;
        interp.allowPublicVariables = true;

        interp.errorHandler = errorHandler;

        return interp.execute(ast);
    }

    public static function setVariable(name:String, value:Dynamic):Void {
        interp.variables.set(name, value);
    }

    public static function getVariable(name:String):Dynamic {
        return interp.variables.get(name);
    }

	private static function errorHandler(error:hscript.Expr.Error) {
		var orgin = error.origin;
		var log = '$orgin:${error.line}: ';
		var err = error.toString();
		if (StringTools.startsWith(err, log)) err = err.substr(log.length);
        Flow.error.report(err);
	}
}
