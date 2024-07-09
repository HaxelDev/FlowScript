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

  public function report(message:Dynamic, exitOnReport:Bool = true):Void {
    var errorMessage = '<red,u>Error! | $message</>';
    if (lastErrorMessage != errorMessage) {
      Console.error(errorMessage);
      lastErrorMessage = errorMessage;
    }
    if (exitOnReport) {
      Sys.exit(0);
    }
  }
}
