package flow;

import logs.*;
import modules.IO;
import modules.Random;
import modules.System;
import modules.File;
import modules.Json;

class Program {
    public var statements:Array<Statement>;

    public function new(statements:Array<Statement>) {
        this.statements = statements;
    }

    public function execute():Void {
        for (statement in statements) {
            statement.execute();
        }
    }
}

class Statement {
    public function execute():Void {}
}

class PrintStatement extends Statement {
    public var expression:Expression;

    public function new(expression:Expression) {
        this.expression = expression;
    }

    public override function execute():Void {
        var value:String = expression.evaluate();
        var lines:Array<String> = value.split("\n");
        for (line in lines) {
            Logger.log(line);
        }
    }
}

class LetStatement extends Statement {
    public var name:String;
    public var initializer:Expression;

    public function new(name:String, initializer:Expression) {
        this.name = name;
        this.initializer = initializer;
    }

    public override function execute():Void {
        Environment.define(name, initializer.evaluate());
    }
}

class VariableExpression extends Expression {
    public var name:String;

    public function new(name:String) {
        this.name = name;
    }

    public override function evaluate():Dynamic {
        return Environment.get(name);
    }
}

class Environment {
    static public var values:Map<String, Dynamic> = new Map();
    static public var functions:Map<String, Function> = new Map();
    static public var modules:Map<String, Dynamic> = new Map();

    static public function define(name:String, value:Dynamic):Void {
        values.set(name, value);
    }

    static public function get(name:String):Dynamic {
        var parts:Array<String> = name.split(".");
        var obj:Dynamic = values.get(parts[0]);

        if (obj == null) {
            Flow.error.report("Undefined variable: " + parts[0]);
            return null;
        }

        for (i in 1...parts.length) {
            if (obj == null) {
                Flow.error.report("Undefined property: " + parts[i - 1]);
                return null;
            }

            if (parts[i] == "length") {
                if (Std.is(obj, String) || Std.is(obj, Array)) {
                    obj = obj.length;
                } else {
                    Flow.error.report("Cannot access 'length' property on non-array/non-string.");
                    return null;
                }
            } else {
                if (Reflect.hasField(obj, parts[i])) {
                    obj = Reflect.field(obj, parts[i]);
                } else {
                    Flow.error.report("Undefined property: " + parts[i]);
                    return null;
                }
            }
        }

        return obj;
    }

    static public function defineFunction(name:String, value:Function):Void {
        functions.set(name, value);
    }

    static public function getFunction(name:String):Function {
        if (!functions.exists(name)) {
            Flow.error.report("Undefined function: " + name);
        }
        return functions.get(name);
    }

    static public function callFunction(name:String, arguments:Array<Dynamic>, context:Dynamic = null):Void {
        var func:Function;
        if (context != null) {
            func = Reflect.field(context, name);
            if (func == null) {
                Flow.error.report("Undefined method: " + name);
                return;
            }
        } else {
            func = functions.get(name);
            if (!functions.exists(name)) {
                Flow.error.report("Undefined function: " + name);
                return;
            }
        }
        if (func.parameters.length != arguments.length) {
            Flow.error.report("Incorrect number of arguments for function: " + name);
            return;
        }
        var oldValues:Map<String, Dynamic> = values.copy();
        for (i in 0...func.parameters.length) {
            values.set(func.parameters[i], arguments[i]);
        }
        func.body.execute();
        values = oldValues;
    }

    static public function defineModule(name:String, module:Dynamic):Void {
        modules.set(name, module);
    }

    static public function getModule(name:String):Dynamic {
        if (!modules.exists(name)) {
            Flow.error.report("Undefined module: " + name);
        }
        return modules.get(name);
    }
}

class Expression {
    public function evaluate():Dynamic {
        return null;
    }
}

class LiteralExpression extends Expression {
    public var value:Dynamic;

    public function new(value:Dynamic) {
        this.value = value;
    }

    public override function evaluate():Dynamic {
        return value;
    }
}

class BinaryExpression extends Expression {
    public var left:Expression;
    public var opera:String;
    public var right:Expression;

    public function new(left:Expression, opera:String, right:Expression) {
        this.left = left;
        this.opera = opera;
        this.right = right;
    }

    public override function evaluate():Dynamic {
        var leftValue = left.evaluate();
        var rightValue = right.evaluate();
    
        var leftIsFloat = Std.is(leftValue, Float);
        var rightIsFloat = Std.is(rightValue, Float);
        var leftIsString = Std.is(leftValue, String);
        var rightIsString = Std.is(rightValue, String);

        if (!leftIsFloat && !leftIsString) {
            Flow.error.report("Unsupported left operand type for operator: " + opera);
            return null;
        }
        if (!rightIsFloat && !rightIsString) {
            Flow.error.report("Unsupported right operand type for operator: " + opera);
            return null;
        }

        if (leftIsFloat) leftValue = cast(leftValue, Float);
        if (rightIsFloat) rightValue = cast(rightValue, Float);

        switch (opera) {
            case "+":
                if (leftIsString || rightIsString) {
                    return Std.string(leftValue) + Std.string(rightValue);
                } else {
                    return leftValue + rightValue;
                }
            case "-":
                if (leftIsString || rightIsString) {
                    Flow.error.report("Unsupported operator for strings: " + opera);
                    return null;
                } else {
                    return leftValue - rightValue;
                }
            case "*":
                if (leftIsString || rightIsString) {
                    Flow.error.report("Unsupported operator for strings: " + opera);
                    return null;
                } else {
                    return leftValue * rightValue;
                }
            case "/":
                if (leftIsString || rightIsString) {
                    Flow.error.report("Unsupported operator for strings: " + opera);
                    return null;
                } else {
                    return Math.floor(leftValue / rightValue);
                }
            case "%":
                if (leftIsString || rightIsString) {
                    Flow.error.report("Unsupported operator for strings: " + opera);
                    return null;
                } else {
                    return leftValue % rightValue;
                }
            case "==":
                if (leftIsString || rightIsString) {
                    return leftValue == rightValue;
                } else {
                    return leftValue == rightValue;
                }
            case "!=":
                if (leftIsString || rightIsString) {
                    return leftValue != rightValue;
                } else {
                    return leftValue != rightValue;
                }
            case "<":
                if (leftIsString || rightIsString) {
                    Flow.error.report("Unsupported operator for strings: " + opera);
                    return null;
                } else {
                    return leftValue < rightValue;
                }
            case "<=":
                if (leftIsString || rightIsString) {
                    Flow.error.report("Unsupported operator for strings: " + opera);
                    return null;
                } else {
                    return leftValue <= rightValue;
                }
            case ">":
                if (leftIsString || rightIsString) {
                    Flow.error.report("Unsupported operator for strings: " + opera);
                    return null;
                } else {
                    return leftValue > rightValue;
                }
            case ">=":
                if (leftIsString || rightIsString) {
                    Flow.error.report("Unsupported operator for strings: " + opera);
                    return null;
                } else {
                    return leftValue >= rightValue;
                }
            case "and":
                if (leftIsString || rightIsString) {
                    Flow.error.report("Unsupported operator 'and' for strings");
                    return null;
                } else {
                    return (leftValue != 0) && (rightValue != 0);
                }
            case "or":
                if (leftIsString || rightIsString) {
                    Flow.error.report("Unsupported operator 'or' for strings");
                    return null;
                } else {
                    return (leftValue != 0) || (rightValue != 0);
                }
            default:
                Flow.error.report("Unknown operator: " + opera);
                return null;
        }
    }
}

class IfStatement extends Statement {
    public var condition:Expression;
    public var thenBranch:Statement;
    public var elseBranch:Statement;

    public function new(condition:Expression, thenBranch:Statement, elseBranch:Statement = null) {
        this.condition = condition;
        this.thenBranch = thenBranch;
        this.elseBranch = elseBranch;
    }

    public override function execute():Void {
        if (condition.evaluate()) {
            thenBranch.execute();
        } else if (elseBranch != null) {
            elseBranch.execute();
        }
    }
}

class ElseStatement extends Statement {
    public var body:Statement;

    public function new(body:Statement) {
        this.body = body;
    }

    public override function execute():Void {
        body.execute();
    }
}

class BlockStatement extends Statement {
    public var statements:Array<Statement>;

    public function new(statements:Array<Statement>) {
        this.statements = statements;
    }

    public override function execute():Void {
        for (statement in statements) {
            statement.execute();
        }
    }
}

class WhileStatement extends Statement {
    public var condition:Expression;
    public var body:Statement;

    public function new(condition:Expression, body:Statement) {
        this.condition = condition;
        this.body = body;
    }

    public override function execute():Void {
        while (condition.evaluate()) {
            try {
                body.execute();
            } catch (e:BreakException) {
                break;
            } catch (e:ContinueException) {
                continue;
            }
        }
    }
}

class ForStatement extends Statement {
    public var variableName:String;
    public var iterableExpression:Expression;
    public var body:Statement;

    public function new(variableName:String, iterableExpression:Expression, body:Statement) {
        this.variableName = variableName;
        this.iterableExpression = iterableExpression;
        this.body = body;
    }

    public override function execute():Void {
        var iterable:Iterable<Dynamic> = iterableExpression.evaluate();

        if (iterable != null) {
            for (item in iterable) {
                Environment.define(variableName, item);
                try {
                    body.execute();
                } catch (e:BreakException) {
                    break;
                } catch (e:ContinueException) {
                    continue;
                }
            }
        } else {
            Flow.error.report("Iterable expression evaluates to null");
        }
    }
}

class RangeExpression extends Expression {
    public var start:Expression;
    public var end:Expression;

    public function new(start:Expression, end:Expression) {
        this.start = start;
        this.end = end;
    }

    public override function evaluate():Iterable<Int> {
        var startValue:Dynamic = start.evaluate();
        var endValue:Dynamic = end.evaluate();

        if (!Std.is(startValue, Int) || !Std.is(endValue, Int)) {
            Flow.error.report("Range start or end value is not a valid integer");
            return null;
        }

        return new RangeIterable(cast(startValue, Int), cast(endValue, Int));
    }    
}

class RangeIterable {
    public var start:Int;
    public var end:Int;

    public function new(start:Int, end:Int) {
        this.start = start;
        this.end = end;
    }

    public function iterator():Iterator<Int> {
        var current:Int = start;

        return {
            hasNext: function():Bool {
                return current <= end;
            },
            next: function():Int {
                return current++;
            }
        };
    }
}

class ArrayLiteralExpression extends Expression {
    public var elements: Array<Expression>;
    
    public function new(elements: Array<Expression>) {
        this.elements = elements;
    }
    
    public override function evaluate(): Dynamic {
        var result: Array<Dynamic> = [];
        for (element in elements) {
            result.push(element.evaluate());
        }
        return result;
    }
}

class FuncStatement extends Statement {
    public var name:String;
    public var parameters:Array<String>;
    public var body:BlockStatement;

    public function new(name:String, parameters:Array<String>, body:BlockStatement) {
        this.name = name;
        this.parameters = parameters;
        this.body = body;
    }

    public override function execute():Void {
        var func = new Function(name, parameters, body);
        Environment.defineFunction(name, func);
    }
}

class CallStatement extends Statement {
    public var name:String;
    public var arguments:Array<Expression>;

    public function new(name:String, arguments:Array<Expression>) {
        this.name = name;
        this.arguments = arguments;
    }

    public override function execute():Void {
        var func:Function = Environment.getFunction(name);
        if (func == null) {
            Flow.error.report("Unknown function: " + name);
            return;
        }
        var args:Array<Dynamic> = [];
        for (arg in arguments) {
            args.push(arg.evaluate());
        }
        func.execute(args);
    }
}

class Function {
    public var name:String;
    public var parameters:Array<String>;
    public var body:BlockStatement;

    public function new(name:String, parameters:Array<String>, body:BlockStatement) {
        this.name = name;
        this.parameters = parameters;
        this.body = body;
    }

    public function execute(args:Array<Dynamic>):Dynamic {
        var oldValues:Map<String, Dynamic> = Environment.values.copy();
        for (i in 0...parameters.length) {
            Environment.define(parameters[i], args[i]);
        }

        try {
            body.execute();
            Environment.values = oldValues;
            return null;
        } catch (e:ReturnValue) {
            Environment.values = oldValues;
            return e.value;
        }
    }
}

class CallExpression extends Expression {
    public var name:String;
    public var arguments:Array<Expression>;

    public function new(name:String, arguments:Array<Expression>) {
        this.name = name;
        this.arguments = arguments;
    }

    public override function evaluate():Dynamic {
        var func:Function = Environment.getFunction(name);
        if (func == null) {
            Flow.error.report("Undefined function: " + name);
            return null;
        }

        var args:Array<Dynamic> = [];
        for (arg in arguments) {
            args.push(arg.evaluate());
        }

        try {
            return func.execute(args);
        } catch (e:ReturnValue) {
            return e.value;
        }
    }
}

class ReturnStatement extends Statement {
    public var expression:Expression;

    public function new(expression:Expression) {
        this.expression = expression;
    }

    public override function execute():Void {
        throw new ReturnValue(expression.evaluate());
    }
}

class ReturnValue extends haxe.Exception {
    public var value:Dynamic;

    public function new(value:Dynamic) {
        this.value = value;
        super('');
    }
}

class ObjectExpression extends Expression {
    public var properties:Map<String, Expression>;

    public function new(properties:Map<String, Expression>) {
        this.properties = properties;
    }

    public override function evaluate():Dynamic {
        var obj:Dynamic = {};
        for (key in properties.keys()) {
            Reflect.setField(obj, key, properties[key].evaluate());
        }
        return obj;
    }
}

class PropertyAccessExpression extends Expression {
    public var obj:Expression;
    public var property:String;

    public function new(obj:Expression, property:String) {
        this.obj = obj;
        this.property = property;
    }

    public override function evaluate():Dynamic {
        var objValue:Dynamic = obj.evaluate();

        if (property == "length") {
            if (Std.is(objValue, String) || Std.is(objValue, Array)) {
                return objValue.length;
            } else {
                Flow.error.report("Cannot access 'length' property on non-array/non-string.");
                return null;
            }
        }

        if (objValue != null && Reflect.hasField(objValue, property)) {
            return Reflect.field(objValue, property);
        } else {
            Flow.error.report("Property '" + property + "' does not exist on object.");
            return null;
        }
    }
}

class ArrayAccessExpression extends Expression {
    public var array:Expression;
    public var index:Expression;

    public function new(array:Expression, index:Expression) {
        this.array = array;
        this.index = index;
    }

    public override function evaluate():Dynamic {
        var arrayValue:Array<Dynamic> = array.evaluate();
        var indexValue:Int = index.evaluate();

        if (arrayValue == null) {
            Flow.error.report("Cannot access element of null array");
            return null;
        }

        if (indexValue < 0 || indexValue >= arrayValue.length) {
            Flow.error.report("Index out of bounds: " + indexValue);
            return null;
        }

        return arrayValue[indexValue];
    }
}

class BreakStatement extends Statement {
    public function new() {}

    public override function execute():Void {
        throw new BreakException();
    }
}

class BreakException extends haxe.Exception {
    public function new() {
        super('Break');
    }
}

class ContinueStatement extends Statement {
    public function new() {}

    public override function execute():Void {
        throw new ContinueException();
    }
}

class ContinueException extends haxe.Exception {
    public function new() {
        super('Continue');
    }
}

class SwitchStatement extends Statement {
    public var expression:Expression;
    public var cases:Array<CaseClause>;
    public var defaultClause:DefaultClause;

    public function new(expression:Expression, cases:Array<CaseClause>, defaultClause:DefaultClause) {
        this.expression = expression;
        this.cases = cases;
        this.defaultClause = defaultClause;
    }

    public override function execute():Void {
        var switchValue = expression.evaluate();
        var executed = false;

        for (caseClause in cases) {
            if (caseClause.caseValue.evaluate() == switchValue) {
                caseClause.caseBody.execute();
                executed = true;
                if (!caseClause.fallsThrough) break;
            }
        }

        if (!executed && defaultClause != null) {
            defaultClause.defaultBody.execute();
        }
    }
}

class CaseClause {
    public var caseValue:Expression;
    public var caseBody:BlockStatement;
    public var fallsThrough:Bool;

    public function new(caseValue:Expression, caseBody:BlockStatement, fallsThrough:Bool) {
        this.caseValue = caseValue;
        this.caseBody = caseBody;
        this.fallsThrough = fallsThrough;
    }
}

class DefaultClause {
    public var defaultBody:BlockStatement;

    public function new(defaultBody:BlockStatement) {
        this.defaultBody = defaultBody;
    }
}

class IOExpression extends Expression {
    public var methodName:String;
    public var arguments:Array<Expression>;

    public function new(methodName:String, arguments:Array<Expression> = null) {
        this.methodName = methodName;
        this.arguments = arguments != null ? arguments : [];
    }

    public override function evaluate():Dynamic {
        var evaluatedArguments:Array<Dynamic> = [];
        for (argument in arguments) {
            evaluatedArguments.push(argument.evaluate());
        }

        switch (methodName) {
            case "print":
                IO.print(evaluatedArguments.join(" "));
                return null;
            case "println":
                IO.println(evaluatedArguments.join(" "));
                return null;
            case "readLine":
                return IO.readLine();
        }

        return null;
    }
}

class IOStatement extends Statement {
    public var methodName:String;
    public var arguments:Array<Expression>;

    public function new(methodName:String, arguments:Array<Expression> = null) {
        this.methodName = methodName;
        this.arguments = arguments != null ? arguments : [];
    }

    public override function execute():Void {
        var evaluatedArguments:Array<Dynamic> = [];
        for (argument in arguments) {
            evaluatedArguments.push(argument.evaluate());
        }

        switch (methodName) {
            case "print":
                IO.print(evaluatedArguments.join(" "));
            case "println":
                IO.println(evaluatedArguments.join(" "));
            case "readLine":
                IO.readLine();
        }
    }
}

class RandomExpression extends Expression {
    public var methodName:String;
    public var arguments:Array<Expression>;

    public function new(methodName:String, arguments:Array<Expression>) {
        this.methodName = methodName;
        this.arguments = arguments;
    }

    public override function evaluate():Int {
        var min:Int = arguments[0].evaluate();
        var max:Int = arguments[1].evaluate();
        return Random.nextInt(min, max);
    }
}

class RandomStatement extends Statement {
    public var methodName:String;
    public var arguments:Array<Expression>;

    public function new(methodName:String, arguments:Array<Expression>) {
        this.methodName = methodName;
        this.arguments = arguments;
    }

    public override function execute():Void {
        var min:Int = arguments[0].evaluate();
        var max:Int = arguments[1].evaluate();
        Random.nextInt(min, max);
    }
}

class SystemExpression extends Expression {
    public var methodName:String;
    public var arguments:Array<Expression>;

    public function new(methodName:String, ?arguments:Array<Expression>) {
        this.methodName = methodName;
        this.arguments = arguments != null ? arguments : [];
    }

    public override function evaluate():Dynamic {
        var evaluatedArguments:Array<Dynamic> = [];
        for (argument in arguments) {
            evaluatedArguments.push(argument.evaluate());
        }

        switch (methodName) {
            case "println":
                System.println(evaluatedArguments.join(" "));
                return null;
            case "exit":
                System.exit();
                return null;
            case "currentDate":
                return System.currentDate();
            case "sleep":
                System.sleep(evaluatedArguments[0]);
                return null;
        }

        return null;
    }
}

class SystemStatement extends Statement {
    public var methodName:String;
    public var arguments:Array<Expression>;

    public function new(methodName:String, ?arguments:Array<Expression>) {
        this.methodName = methodName;
        this.arguments = arguments != null ? arguments : [];
    }

    public override function execute():Void {
        var evaluatedArguments:Array<Dynamic> = [];
        for (argument in arguments) {
            evaluatedArguments.push(argument.evaluate());
        }

        switch (methodName) {
            case "println":
                System.println(evaluatedArguments.join(" "));
            case "exit":
                System.exit();
            case "currentDate":
                System.currentDate();
            case "sleep":
                System.sleep(evaluatedArguments[0]);
        }
    }
}

class FileExpression extends Expression {
    public var methodName:String;
    public var arguments:Array<Expression>;

    public function new(methodName:String, ?arguments:Array<Expression>) {
        this.methodName = methodName;
        this.arguments = arguments != null ? arguments : [];
    }

    public override function evaluate():Dynamic {
        var evaluatedArguments:Array<Dynamic> = [];
        for (argument in arguments) {
            evaluatedArguments.push(argument.evaluate());
        }

        switch (methodName) {
            case "readFile":
                return File.readFile(evaluatedArguments[0]);
            case "writeFile":
                File.writeFile(evaluatedArguments[0], evaluatedArguments[1]);
                return null;
            case "exists":
                return File.exists(evaluatedArguments[0]);
        }

        return null;
    }
}

class FileStatement extends Statement {
    public var methodName:String;
    public var arguments:Array<Expression>;

    public function new(methodName:String, arguments:Array<Expression>) {
        this.methodName = methodName;
        this.arguments = arguments != null ? arguments : [];
    }

    public override function execute():Void {
        var evaluatedArguments:Array<Dynamic> = [];
        for (argument in arguments) {
            evaluatedArguments.push(argument.evaluate());
        }

        switch (methodName) {
            case "readFile":
                File.readFile(evaluatedArguments[0]);
            case "writeFile":
                File.writeFile(evaluatedArguments[0], evaluatedArguments[1]);
            case "exists":
                File.exists(evaluatedArguments[0]);
        }
    }
}

class JsonExpression extends Expression {
    public var methodName:String;
    public var arguments:Array<Expression>;

    public function new(methodName:String, arguments:Array<Expression>) {
        this.methodName = methodName;
        this.arguments = arguments != null ? arguments : [];
    }

    public override function evaluate():Dynamic {
        var evaluatedArguments:Array<Dynamic> = [];
        for (argument in arguments) {
            evaluatedArguments.push(argument.evaluate());
        }

        switch (methodName) {
            case "parse":
                return Json.parse(evaluatedArguments[0]);
            case "stringify":
                return Json.stringify(evaluatedArguments[0]);
            case "isValid":
                return Json.isValid(evaluatedArguments[0]);
        }

        return null;
    }
}

class JsonStatement extends Statement {
    public var methodName:String;
    public var arguments:Array<Expression>;

    public function new(methodName:String, arguments:Array<Expression>) {
        this.methodName = methodName;
        this.arguments = arguments != null ? arguments : [];
    }

    public override function execute():Void {
        var evaluatedArguments:Array<Dynamic> = [];
        for (argument in arguments) {
            evaluatedArguments.push(argument.evaluate());
        }

        switch (methodName) {
            case "parse":
                Json.parse(evaluatedArguments[0]);
            case "stringify":
                Json.stringify(evaluatedArguments[0]);
            case "isValid":
                Json.isValid(evaluatedArguments[0]);
        }
    }
}
