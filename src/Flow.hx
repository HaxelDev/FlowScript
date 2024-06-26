package;

import flow.Lexer;
import flow.Parser;
import flow.Program;
import sys.FileSystem;
import sys.io.File;
import logs.*;

using StringTools;

class Flow {
  public static var error = Error.getInstance();

  static function runScript(scriptFile:String) {
    if (!FileSystem.exists(scriptFile)) {
      error.report('Script file "$scriptFile" does not exist.');
    }
    var code = File.getContent(scriptFile);
    var tokens:Array<Token> = Lexer.tokenize(code);
    var parser:Parser = new Parser(tokens);
    var program:Program = parser.parse();
    program.execute();
  }

  static function runInteractive() {
    var input:String;
    var parser:Parser = new Parser([]);

    while (true) {
      Sys.print(">>> ");
      input = Sys.stdin().readLine().trim();

      if (input == "exit" || input == "quit") {
        break;
      }

      var tokens:Array<Token> = Lexer.tokenize(input);
      parser = new Parser(tokens);
      var program:Program = parser.parse();
      for (statement in program.statements) {
        statement.execute();
      }
    }
  }

  static function main() {
    var args = Sys.args();
    var command = args.length > 0? args[0] : null;
    var scriptFile = args.length > 1? args[1] : null;

    switch (command) {
      case "run":
        if (scriptFile!= null && scriptFile.endsWith(".fl")) {
          runScript(scriptFile);
        } else {
          error.report('Invalid script file or format. Use.fl files');
        }
      case "interactive":
        runInteractive();
      case "version":
        runVersion();
      case "help":
        printHelp();
      default:
        printHelp();
    }
  }

  static function runVersion() {
    Logger.log('Flow Script version 0.1.0');
  }

  static function printHelp() {
    Logger.log('Flow Scripting Language');
    Logger.log('---------------------');
    Logger.log('Usage: flow run [file]');
    Logger.log('       flow interactive');
    Logger.log('       flow version');
    Logger.log('       flow help');
  }
}
