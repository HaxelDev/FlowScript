package modules;

class ModuleManager {
    static private var modules:Map<String, Dynamic> = new Map();

    static public function registerModule(moduleName:String, moduleInstance:Dynamic):Void {
        modules.set(moduleName, moduleInstance);
    }

    static public function getModule(moduleName:String):Dynamic {
        if (modules.exists(moduleName)) {
            return modules.get(moduleName);
        } else {
            Flow.error.report("Module not found: " + moduleName);
            return null;
        }
    }
}
