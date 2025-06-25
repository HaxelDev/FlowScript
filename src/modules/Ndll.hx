package modules;

class Ndll {
	public static function getFunction(ndll:String, name:String, args:Int):Dynamic {
		if (!File.exists(ndll)) {
			Flow.error.report('Couldn\'t find ndll at ${ndll}.');
			return noop;
		}
		var func = lime.system.CFFI.load(File.readFile(ndll), name, args);
		if (func == null) {
			Flow.error.report('Method ${name} in ndll ${ndll} with ${args} args was not found.');
			return noop;
		}
		return func;
	}
	@:dox(hide) @:noCompletion static function noop() {}
}
