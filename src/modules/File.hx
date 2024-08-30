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

    public static function appendToFile(filePath:String, content:String):Void {
        var file = sys.io.File.append(filePath, true);
        file.writeString(content);
        file.close();
    }

    public static function deleteFile(filePath:String):Void {
        if (FileSystem.exists(filePath)) {
            FileSystem.deleteFile(filePath);
        }
    }

    public static function copyFile(sourcePath:String, destinationPath:String):Void {
        if (FileSystem.exists(sourcePath)) {
            sys.io.File.copy(sourcePath, destinationPath);
        }
    }

    public static function renameFile(oldPath:String, newPath:String):Void {
        if (FileSystem.exists(oldPath)) {
            FileSystem.rename(oldPath, newPath);
        }
    }

    public static function readLines(filePath:String):Array<String> {
        if (!FileSystem.exists(filePath)) {
            return [];
        }
    
        var file = sys.io.File.read(filePath, true);
        var lines = [];
        while (!file.eof()) {
            lines.push(file.readLine());
        }
        file.close();
        return lines;
    }

    public static function getFileSize(filePath:String):Int {
        if (FileSystem.exists(filePath)) {
            return FileSystem.stat(filePath).size;
        }
        return -1;
    }

    public static function listFilesInDirectory(directoryPath:String):Array<String> {
        if (FileSystem.exists(directoryPath) && FileSystem.isDirectory(directoryPath)) {
            return FileSystem.readDirectory(directoryPath);
        }
        return [];
    }

    public static function createDirectory(directoryPath:String):Void {
        if (!FileSystem.exists(directoryPath)) {
            FileSystem.createDirectory(directoryPath);
        }
    }

    public static function getFileExtension(filePath:String):String {
        var parts = filePath.split(".");
        if (parts.length > 1) {
            return parts.pop();
        }
        return "";
    }
}
