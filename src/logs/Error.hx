package logs;

class Error {
  private static var instance:Error;
  private var lastErrorMessage:String;

  private function new() {}

  public static function getInstance():Error {
    if (instance == null) {
      instance = new Error();
    }
    return instance;
  }

  public function report(message:Dynamic, lineNumber:Int = -1, exitOnReport:Bool = true):Void {
    var errorMessage:String;
    if (lineNumber == -1) {
      errorMessage = '<red,u>Error: $message</>';
    } else {
      errorMessage = '<red,u>Error on line $lineNumber: $message</>';
    }
    if (lastErrorMessage != errorMessage) {
      Console.error(errorMessage);
      lastErrorMessage = errorMessage;
    }
    if (exitOnReport) {
      Sys.exit(0);
    }
  }
}
