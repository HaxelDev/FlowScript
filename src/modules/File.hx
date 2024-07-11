package modules;

import sys.FileSystem;

class File {
    public static function readFile(filePath:String):String {
        return sys.io.File.getContent(filePath);
    }

    public static function writeFile(filePath:String, content:String):Void {
        var file = sys.io.File.write(filePath, true);
        file.writeString(content);
        file.close();
    }

    public static function exists(filePath:String):Bool {
        return FileSystem.exists(filePath);
    }
}
