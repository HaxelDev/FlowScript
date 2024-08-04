package;

import flow.Lexer;
import flow.Parser;
import flow.Program;
import sys.FileSystem;
import sys.io.File;
import haxe.Json;
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
      Sys.print("flow> ");
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

  static function createProject(projectName:String) {
    var projectDir = projectName;
    if (FileSystem.exists(projectDir)) {
      error.report('Project "$projectName" already exists.');
      return;
    }

    FileSystem.createDirectory(projectDir);
    var srcDir = projectDir + "/src";
    FileSystem.createDirectory(srcDir);

    var projectData = {
      name: projectName,
      version: "0.1.0",
      main: "main.flow",
      src: "src",
      dependencies: {}
    };
    var jsonData = Json.stringify(projectData, null, "  ");
    File.saveContent(projectDir + "/project.json", jsonData);

    var mainFlowContent = 'print("Hello, this is the main script!")\n';
    File.saveContent(srcDir + "/main.flow", mainFlowContent);

    Logger.log('Project "$projectName" created.');
  }

  static function buildProject() {
    if (!FileSystem.exists("project.json")) {
      error.report('No project.json file found in the current directory.');
      return;
    }
  
    var jsonData = File.getContent("project.json");
    var projectData:Dynamic = Json.parse(jsonData);
  
    var mainScriptPath = projectData.src + "/" + projectData.main;
    if (!FileSystem.exists(mainScriptPath)) {
      error.report('Main script "${mainScriptPath}" does not exist.');
      return;
    }
    runScript(mainScriptPath);
  }

  static function main() {
    var args = Sys.args();
    var command = args.length > 0? args[0] : null;
    var param = args.length > 1 ? args[1] : null;

    switch (command) {
      case "run":
        if (param != null) {
          runScript(param);
        } else {
          error.report('Invalid script file.');
        }
      case "create":
        if (param != null) {
          createProject(param);
        } else {
          error.report('Invalid project name.');
        }
      case "build":
        buildProject();
      case "interactive":
        runInteractive();
      case "version":
        runVersion();
      default:
        printHelp();
    }
  }

  static function runVersion() {
    Logger.log('Flow Script version 0.7.0');
  }

  static function printHelp() {
    Logger.log('Flow Scripting Language');
    Logger.log('---------------------');
    Logger.log('Usage: flow run [file]');
    Logger.log('       flow create [project name]');
    Logger.log('       flow build');
    Logger.log('       flow interactive');
    Logger.log('       flow version');
  }
}
