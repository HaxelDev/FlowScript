package flow;

import logs.*;
import modules.*;
import modules.Date;

using StringTools;

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

class ErrorStatement extends Statement {
    public var expression:Expression;

    public function new(expression:Expression) {
        this.expression = expression;
    }

    public override function execute():Void {
        var value:String = expression.evaluate();
        var lines:Array<String> = value.split("\n");
        for (line in lines) {
            Flow.error.report(line);
        }
    }
}

class LetStatement extends Statement {
    public var name: String;
    public var opera: String;
    public var initializer: Expression;
    public var isPrefix: Bool;

    public function new(name: String, opera: String, initializer: Expression = null, isPrefix: Bool = false) {
        this.name = name;
        this.opera = opera;
        this.initializer = initializer;
        this.isPrefix = isPrefix;
    }

    public override function execute(): Void {
        var value: Dynamic = initializer != null ? initializer.evaluate() : null;

        if (name == "this") {
            Flow.error.report("'this' keyword can only be used in object context", -1);
            return;
        }

        var parts = name.split(".");
        var baseName = parts.shift();
        var propertyName = parts.join(".");

        if (baseName == "this") {
            var currentInstance = Environment.get("this");
            if (currentInstance == null) {
                Flow.error.report("Current instance ('this') is not defined", -1);
                return;
            }
            handleAssignment(currentInstance, propertyName, value);
        } else {
            switch (opera) {
                case "=":
                    if (parts.length == 0) {
                        Environment.define(baseName, value);
                    } else {
                        var baseObject = Environment.get(baseName);
                        if (baseObject != null) {
                            Reflect.setField(baseObject, propertyName, value);
                        } else {
                            Flow.error.report("Base object '" + baseName + "' is not defined", -1);
                        }
                    }
                case "+=":
                    var existingValue: Dynamic = (parts.length == 0) ? Environment.get(baseName) : Reflect.field(Environment.get(baseName), propertyName);
                    if (existingValue != null) {
                        if (Std.is(existingValue, Int) || Std.is(existingValue, Float)) {
                            var newValue: Float = cast(existingValue, Float) + cast(value, Float);
                            if (parts.length == 0) {
                                Environment.define(baseName, newValue);
                            } else {
                                Reflect.setField(Environment.get(baseName), propertyName, newValue);
                            }
                        } else if (Std.is(existingValue, String)) {
                            var existingString: String = cast(existingValue, String);
                            var newValue: String = existingString + cast(value, String);
                            if (parts.length == 0) {
                                Environment.define(baseName, newValue);
                            } else {
                                Reflect.setField(Environment.get(baseName), propertyName, newValue);
                            }
                        } else {
                            Flow.error.report("Variable '" + baseName + "' is not suitable for '+=' operation", -1);
                        }
                    }
                case "-=":
                    var existingValue: Dynamic = (parts.length == 0) ? Environment.get(baseName) : Reflect.field(Environment.get(baseName), propertyName);
                    if (existingValue != null) {
                        if (Std.is(existingValue, Int) || Std.is(existingValue, Float)) {
                            var newValue: Float = cast(existingValue, Float) - cast(value, Float);
                            if (parts.length == 0) {
                                Environment.define(baseName, newValue);
                            } else {
                                Reflect.setField(Environment.get(baseName), propertyName, newValue);
                            }
                        } else if (Std.is(existingValue, String)) {
                            var existingString: String = cast(existingValue, String);
                            var newValue: String = existingString.split(cast(value, String)).join("");
                            if (parts.length == 0) {
                                Environment.define(baseName, newValue);
                            } else {
                                Reflect.setField(Environment.get(baseName), propertyName, newValue);
                            }
                        } else {
                            Flow.error.report("Variable '" + baseName + "' is not suitable for '-=' operation", -1);
                        }
                    }
                case "++":
                    var existingValue: Dynamic = (parts.length == 0) ? Environment.get(baseName) : Reflect.field(Environment.get(baseName), propertyName);
                    if (existingValue != null) {
                        if (Std.is(existingValue, Int) || Std.is(existingValue, Float)) {
                            var incrementValue: Float = isPrefix ? 1 : 0;
                            var newValue: Float = cast(existingValue, Float) + incrementValue;
                            if (parts.length == 0) {
                                Environment.define(baseName, newValue);
                            } else {
                                Reflect.setField(Environment.get(baseName), propertyName, newValue);
                            }
                            if (!isPrefix) {
                                newValue += 1;
                                if (parts.length == 0) {
                                    Environment.define(baseName, newValue);
                                } else {
                                    Reflect.setField(Environment.get(baseName), propertyName, newValue);
                                }
                            }
                        } else {
                            Flow.error.report("Variable '" + baseName + "' is not suitable for '++' operation", -1);
                        }
                    }
                case "--":
                    var existingValue: Dynamic = (parts.length == 0) ? Environment.get(baseName) : Reflect.field(Environment.get(baseName), propertyName);
                    if (existingValue != null) {
                        if (Std.is(existingValue, Int) || Std.is(existingValue, Float)) {
                            var decrementValue: Float = isPrefix ? 1 : 0;
                            var newValue: Float = cast(existingValue, Float) - decrementValue;
                            if (parts.length == 0) {
                                Environment.define(baseName, newValue);
                            } else {
                                Reflect.setField(Environment.get(baseName), propertyName, newValue);
                            }
                            if (!isPrefix) {
                                newValue -= 1;
                                if (parts.length == 0) {
                                    Environment.define(baseName, newValue);
                                } else {
                                    Reflect.setField(Environment.get(baseName), propertyName, newValue);
                                }
                            }
                        } else {
                            Flow.error.report("Variable '" + baseName + "' is not suitable for '--' operation", -1);
                        }
                    }
                default:
                    Flow.error.report("Unsupported assignment operator: " + opera);
            }
        }
    }

    private function handleAssignment(currentInstance: Dynamic, propertyName: String, value: Dynamic): Void {
        switch (opera) {
            case "=":
                Reflect.setField(currentInstance, propertyName, value);
            case "+=":
                var existingValue: Dynamic = Reflect.field(currentInstance, propertyName);
                if (existingValue != null) {
                    if (Std.is(existingValue, Int) || Std.is(existingValue, Float)) {
                        var newValue: Float = cast(existingValue, Float) + cast(value, Float);
                        Reflect.setField(currentInstance, propertyName, newValue);
                    } else if (Std.is(existingValue, String)) {
                        var existingString: String = cast(existingValue, String);
                        var newValue: String = existingString + cast(value, String);
                        Reflect.setField(currentInstance, propertyName, newValue);
                    } else {
                        Flow.error.report("Property '" + propertyName + "' is not suitable for '+=' operation", -1);
                    }
                }
            case "-=":
                var existingValue: Dynamic = Reflect.field(currentInstance, propertyName);
                if (existingValue != null) {
                    if (Std.is(existingValue, Int) || Std.is(existingValue, Float)) {
                        var newValue: Float = cast(existingValue, Float) - cast(value, Float);
                        Reflect.setField(currentInstance, propertyName, newValue);
                    } else if (Std.is(existingValue, String)) {
                        var existingString: String = cast(existingValue, String);
                        var newValue: String = existingString.split(cast(value, String)).join("");
                        Reflect.setField(currentInstance, propertyName, newValue);
                    } else {
                        Flow.error.report("Property '" + propertyName + "' is not suitable for '-=' operation", -1);
                    }
                }
            case "++":
                var existingValue: Dynamic = Reflect.field(currentInstance, propertyName);
                if (existingValue != null) {
                    if (Std.is(existingValue, Int) || Std.is(existingValue, Float)) {
                        var incrementValue: Float = isPrefix ? 1 : 0;
                        var newValue: Float = cast(existingValue, Float) + incrementValue;
                        Reflect.setField(currentInstance, propertyName, newValue);
                        if (!isPrefix) {
                            newValue += 1;
                            Reflect.setField(currentInstance, propertyName, newValue);
                        }
                    } else {
                        Flow.error.report("Property '" + propertyName + "' is not suitable for '++' operation", -1);
                    }
                }
            case "--":
                var existingValue: Dynamic = Reflect.field(currentInstance, propertyName);
                if (existingValue != null) {
                    if (Std.is(existingValue, Int) || Std.is(existingValue, Float)) {
                        var decrementValue: Float = isPrefix ? 1 : 0;
                        var newValue: Float = cast(existingValue, Float) - decrementValue;
                        Reflect.setField(currentInstance, propertyName, newValue);
                        if (!isPrefix) {
                            newValue -= 1;
                            Reflect.setField(currentInstance, propertyName, newValue);
                        }
                    } else {
                        Flow.error.report("Property '" + propertyName + "' is not suitable for '--' operation", -1);
                    }
                }
            default:
                Flow.error.report("Unsupported assignment operator: " + opera);
        }
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
    static public var currentScope:Scope = new Scope();

    static public function define(name:String, value:Dynamic):Void {
        values.set(name, value);
    }

    static public function get(name: String): Dynamic {
        var parts: Array<String> = name.split(".");
        var obj: Dynamic = values.get(parts[0]);

        if (obj == null && currentScope != null) {
            for (letStatement in currentScope.letStatements) {
                if (letStatement.name == parts[0]) {
                    return null;
                }
            }
        }

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

    static public function defineFunction(name:String, func:Dynamic):Void {
        functions.set(name, func);
    }

    static public function getFunction(name:String, context:Dynamic = null):Dynamic {
        if (context != null) {
            var parts: Array<String> = name.split(".");
            var methodName: String = parts.pop();
            var obj: Dynamic = context;

            for (part in parts) {
                if (obj == null) {
                    Flow.error.report("Undefined property: " + part);
                    return null;
                }

                if (Reflect.hasField(obj, part)) {
                    obj = Reflect.field(obj, part);
                } else {
                    Flow.error.report("Undefined property: " + part);
                    return null;
                }
            }

            var func: Dynamic = Reflect.field(obj, methodName);
            if (func == null) {
                var variable = values.get(name);
                if (Std.is(variable, Function)) {
                    return variable;
                }
                Flow.error.report("Undefined function: " + name);
            }
            return func;
        } else {
            var func: Dynamic = functions.get(name);
            if (func == null) {
                var variable = values.get(name);
                if (Std.is(variable, Function)) {
                    return variable;
                }
                Flow.error.report("Undefined function: " + name);
            }
            return func;
        }
    }

    static public function callFunction(name: String, arguments: Array<Dynamic>, context: Dynamic = null): Dynamic {
        var func: Dynamic = getFunction(name, context);

        if (func == null) {
            Flow.error.report("Function or method could not be found: " + name);
            return null;
        }

        if (Std.is(func, Function)) {
            try {
                return Reflect.callMethod(context, func, arguments);
            } catch (e: Dynamic) {
                Flow.error.report("Error calling function: " + name + " - " + e.toString());
                return null;
            }
        } else {
            Flow.error.report("Retrieved item is not a function: " + name);
            return null;
        }
    }

    static public function push(array:Array<Dynamic>, value:Dynamic):Void {
        if (array == null) {
            Flow.error.report("Cannot push to null array");
            return;
        }
        array.push(value);
    }

    static public function pop(array:Array<Dynamic>):Dynamic {
        if (array == null) {
            Flow.error.report("Cannot pop from null array");
            return null;
        }
        if (array.length == 0) {
            Flow.error.report("Cannot pop from empty array");
            return null;
        }
        return array.pop();
    }
}

class Scope {
    public var letStatements:Array<LetStatement> = new Array();
    public var parentScope:Scope;
    public var context:Dynamic;

    public function new(parentScope:Scope = null, context:Dynamic = null) {
        this.parentScope = parentScope;
        this.context = context;
    }

    public function getContext():Dynamic {
        if (context != null) {
            return context;
        } else if (parentScope != null) {
            return parentScope.getContext();
        } else {
            return null;
        }
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
        var leftValue:Dynamic = left.evaluate();
        var rightValue:Dynamic = right.evaluate();

        var leftIsFloat:Bool = Std.is(leftValue, Float);
        var rightIsFloat:Bool = Std.is(rightValue, Float);
        var leftIsString:Bool = Std.is(leftValue, String);
        var rightIsString:Bool = Std.is(rightValue, String);
        var leftIsBool:Bool = Std.is(leftValue, Bool);
        var rightIsBool:Bool = Std.is(rightValue, Bool);

        if (opera == "and" || opera == "or") {
            if (!leftIsBool) {
                Flow.error.report("Unsupported left operand type for 'and'/'or': " + Type.typeof(leftValue));
                return null;
            }
            if (!rightIsBool) {
                Flow.error.report("Unsupported right operand type for 'and'/'or': " + Type.typeof(rightValue));
                return null;
            }

            var leftBool:Bool = cast(leftValue, Bool);
            var rightBool:Bool = cast(rightValue, Bool);

            switch (opera) {
                case "and":
                    return leftBool && rightBool;
                case "or":
                    return leftBool || rightBool;
                default:
                    Flow.error.report("Unknown logical operator: " + opera);
                    return null;
            }
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
                    Flow.error.report("Unsupported operator '-' for strings");
                    return null;
                } else {
                    return leftValue - rightValue;
                }
            case "*":
                if (leftIsString || rightIsString) {
                    Flow.error.report("Unsupported operator '*' for strings");
                    return null;
                } else {
                    return leftValue * rightValue;
                }
            case "/":
                if (leftIsString || rightIsString) {
                    Flow.error.report("Unsupported operator '/' for strings");
                    return null;
                } else if (rightValue == 0) {
                    Flow.error.report("Division by zero error");
                    return null;
                } else {
                    return leftValue / rightValue;
                }
            case "%":
                if (leftIsString || rightIsString) {
                    Flow.error.report("Unsupported operator '%' for strings");
                    return null;
                } else if (rightValue == 0) {
                    Flow.error.report("Modulo by zero error");
                    return null;
                } else {
                    return leftValue % rightValue;
                }
            case "==":
                return leftValue == rightValue;
            case "!=":
                return leftValue != rightValue;
            case "<":
                if (leftIsString || rightIsString) {
                    Flow.error.report("Unsupported operator '<' for strings");
                    return null;
                } else {
                    return leftValue < rightValue;
                }
            case "<=":
                if (leftIsString || rightIsString) {
                    Flow.error.report("Unsupported operator '<=' for strings");
                    return null;
                } else {
                    return leftValue <= rightValue;
                }
            case ">":
                if (leftIsString || rightIsString) {
                    Flow.error.report("Unsupported operator '>' for strings");
                    return null;
                } else {
                    return leftValue > rightValue;
                }
            case ">=":
                if (leftIsString || rightIsString) {
                    Flow.error.report("Unsupported operator '>=' for strings");
                    return null;
                } else {
                    return leftValue >= rightValue;
                }
            default:
                Flow.error.report("Unknown operator: " + opera);
                return null;
        }
    }
}

class TernaryExpression extends Expression {
    public var condition:Expression;
    public var trueBranch:Expression;
    public var falseBranch:Expression;

    public function new(condition:Expression, trueBranch:Expression, falseBranch:Expression) {
        this.condition = condition;
        this.trueBranch = trueBranch;
        this.falseBranch = falseBranch;
    }

    public override function evaluate():Dynamic {
        var conditionValue = condition.evaluate();
        if (Std.is(conditionValue, Bool)) {
            return cast(conditionValue, Bool) ? trueBranch.evaluate() : falseBranch.evaluate();
        } else {
            Flow.error.report("Condition in ternary operator must evaluate to a Boolean");
            return null;
        }
    }
}

class ConcatenationExpression extends Expression {
    public var parts:Array<Expression>;

    public function new(parts:Array<Expression>) {
        this.parts = parts;
    }

    public override function evaluate():Dynamic {
        var result:String = "";
        for (part in parts) {
            var partValue:Dynamic = part.evaluate();
            if (partValue == null) {
                partValue = "null";
            } else {
                partValue = Std.string(partValue);
            }
            result += partValue;
        }
        return result;
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
    public var parameters:Array<Parameter>;
    public var body:BlockStatement;

    public function new(name:String, parameters:Array<Parameter>, body:BlockStatement) {
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
            var variable = Environment.get(name);
            if (Std.is(variable, Function)) {
                func = variable;
            } else {
                Flow.error.report("Unknown function or variable: " + name);
                return;
            }
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
    public var parameters:Array<Parameter>;
    public var body:BlockStatement;

    public function new(name:String, parameters:Array<Parameter>, body:BlockStatement) {
        this.name = name;
        this.parameters = parameters;
        this.body = body;
    }

    public function execute(args:Array<Dynamic>):Dynamic {
        var oldValues:Map<String, Dynamic> = Environment.values.copy();
        for (i in 0...parameters.length) {
            if (i < args.length) {
                Environment.define(parameters[i].name, args[i]);
            } else if (parameters[i].defaultValue != null) {
                Environment.define(parameters[i].name, parameters[i].defaultValue.evaluate());
            } else {
                Flow.error.report("Missing argument for parameter '" + parameters[i].name + "'");
                return null;
            }
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
            var variable = Environment.get(name);
            if (Std.is(variable, Function)) {
                func = variable;
            } else {
                Flow.error.report("Unknown function or variable: " + name);
                return null;
            }
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

class FunctionLiteralExpression extends Expression {
    public var parameters:Array<Parameter>;
    public var body:BlockStatement;

    public function new(parameters:Array<Parameter>, body:BlockStatement) {
        this.parameters = parameters;
        this.body = body;
    }

    public override function evaluate():Dynamic {
        return new Function(null, parameters, body);
    }
}

class MethodCallExpression extends Expression {
    public var objectName: String;
    public var methodName: String;
    public var arguments: Array<Expression>;

    public function new(objectName: String, methodName: String, arguments: Array<Expression>) {
        this.objectName = objectName;
        this.methodName = methodName;
        this.arguments = arguments;
    }

    public override function evaluate(): Dynamic {
        var obj: Dynamic = Environment.get(objectName);
        if (obj == null) {
            Flow.error.report("Undefined object: " + objectName);
            return null;
        }

        var func: Dynamic = Environment.getFunction(methodName, obj);
        if (func == null || !(func is Function)) {
            Flow.error.report("Undefined method: " + methodName);
            return null;
        }

        var args: Array<Dynamic> = [];
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

class MethodCallStatement extends Statement {
    public var objectName: String;
    public var methodName: String;
    public var arguments: Array<Expression>;

    public function new(objectName: String, methodName: String, arguments: Array<Expression>) {
        this.objectName = objectName;
        this.methodName = methodName;
        this.arguments = arguments;
    }

    public override function execute():Void {
        var obj: Dynamic = Environment.get(objectName);
        if (obj == null) {
            Flow.error.report("Undefined object: " + objectName);
            return;
        }

        var func: Dynamic = Environment.getFunction(methodName, obj);
        if (func == null || !(func is Function)) {
            Flow.error.report("Undefined method: " + methodName);
            return;
        }

        var args: Array<Dynamic> = [];
        for (arg in arguments) {
            args.push(arg.evaluate());
        }
        func.execute(args);
    }
}

class Parameter {
    public var name:String;
    public var defaultValue:Expression;

    public function new(name:String, defaultValue:Expression = null) {
        this.name = name;
        this.defaultValue = defaultValue;
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

        if (indexValue < 0) {
            indexValue += arrayValue.length;
        }

        if (indexValue < 0 || indexValue >= arrayValue.length) {
            Flow.error.report("Index out of bounds: " + indexValue);
            return null;
        }

        return arrayValue[indexValue];
    }
}

class ArrayAssignmentStatement extends Statement {
    public var arrayName:String;
    public var index:Expression;
    public var value:Expression;

    public function new(arrayName:String, index:Expression, value:Expression) {
        this.arrayName = arrayName;
        this.index = index;
        this.value = value;
    }

    public override function execute():Void {
        var arrayValue:Array<Dynamic> = Environment.get(arrayName);
        if (arrayValue == null) {
            Flow.error.report("Undefined array: " + arrayName);
            return;
        }

        var indexValue:Int = index.evaluate();

        if (indexValue < 0) {
            indexValue += arrayValue.length;
        }

        if (indexValue < 0 || indexValue >= arrayValue.length) {
            Flow.error.report("Index out of bounds: " + indexValue);
            return;
        }

        arrayValue[indexValue] = value.evaluate();
        Environment.define(arrayName, arrayValue);
    }
}

class UnaryExpression extends Expression {
    public var opera:String;
    public var right:Expression;
    public var isPrefix:Bool;

    public function new(opera:String, right:Expression, isPrefix:Bool) {
        this.opera = opera;
        this.right = right;
        this.isPrefix = isPrefix;
    }

    public override function evaluate():Dynamic {
        var value = right.evaluate();
        var variableName:String = null;

        if (opera == "-") {
            if (Std.is(value, Int) || Std.is(value, Float)) {
                return -Std.parseFloat(Std.string(value));
            } else {
                Flow.error.report("Unary minus operator can only be applied to numeric values.");
                return null;
            }
        }

        if (Std.is(right, VariableExpression)) {
            var variableExpr = cast right;
            variableName = variableExpr.name;
        } else {
            Flow.error.report("Unary operator '" + opera + "' can only be applied to variables.");
            return null;
        }

        var currentValue = Environment.get(variableName);

        switch (opera) {
            case "++":
                if (isPrefix) {
                    currentValue += 1;
                    Environment.define(variableName, currentValue);
                    return currentValue;
                } else {
                    var oldValue = currentValue;
                    currentValue += 1;
                    Environment.define(variableName, currentValue);
                    return oldValue;
                }
            case "--":
                if (isPrefix) {
                    currentValue -= 1;
                    Environment.define(variableName, currentValue);
                    return currentValue;
                } else {
                    var oldValue = currentValue;
                    currentValue -= 1;
                    Environment.define(variableName, currentValue);
                    return oldValue;
                }
            case "not":
                if (Std.is(value, Bool)) {
                    return !cast(value);
                } else {
                    Flow.error.report("Logical 'not' operator can only be applied to boolean values.");
                    return null;
                }
            default:
                Flow.error.report("Unknown unary operator: " + opera);
                return null;
        }
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

class ImportStatement extends Statement {
    public var scriptFile:String;

    public function new(scriptFile:String) {
        this.scriptFile = scriptFile;
    }

    public override function execute():Void {
        var scriptPath = getScriptPath();
        if (!sys.FileSystem.exists(scriptPath)) {
            Flow.error.report('Script file "$scriptPath" does not exist.');
        }
        var code = sys.io.File.getContent(scriptPath);
        var tokens:Array<flow.Lexer.Token> = Lexer.tokenize(code);
        var parser:Parser = new Parser(tokens);
        var program:Program = parser.parse();
        program.execute();
    }

    private function getScriptPath():String {
        if (sys.FileSystem.exists("project.json")) {
            var jsonData = sys.io.File.getContent("project.json");
            var projectData:Dynamic = Json.parse(jsonData);
            return projectData.src + "/" + scriptFile;
        } else {
            return scriptFile;
        }
    }
}

class TryStatement extends Statement {
    public var tryBlock: BlockStatement;
    public var catchClauses: Array<CatchClause>;

    public function new(tryBlock: BlockStatement, catchClauses: Array<CatchClause>) {
        this.tryBlock = tryBlock;
        this.catchClauses = catchClauses;
    }

    public override function execute():Void {
        try {
            tryBlock.execute();
        } catch (e:Dynamic) {
            for (catchClause in catchClauses) {
                if (catchClause.variableName == null || catchClause.variableName == "") {
                    catchClause.catchBlock.execute();
                } else {
                    Environment.define(catchClause.variableName, e);
                    catchClause.catchBlock.execute();
                }
            }
        }
    }
}

class CatchClause {
    public var variableName: String;
    public var catchBlock: BlockStatement;

    public function new(variableName: String, catchBlock: BlockStatement) {
        this.variableName = variableName;
        this.catchBlock = catchBlock;
    }
}

class EnumStatement extends Statement {
    public var name:String;
    public var values:Array<EnumValue>;

    public function new(name:String, values:Array<EnumValue>) {
        this.name = name;
        this.values = values;
    }

    public override function execute():Void {
        var enumObject:Dynamic = {};
        var currentIndex:Int = 0;

        for (value in values) {
            var enumValue:Dynamic;

            if (value.value != null) {
                enumValue = value.value.evaluate();
            } else {
                enumValue = currentIndex;
            }

            Reflect.setField(enumObject, value.name, enumValue);
            currentIndex++;
        }

        Environment.define(name, enumObject);
    }
}

class EnumValue {
    public var name:String;
    public var value:Expression;

    public function new(name:String, value:Expression) {
        this.name = name;
        this.value = value;
    }
}

class ClassStatement extends Statement {
    public var name:String;
    public var properties:Array<Statement>;
    public var methods:Array<Statement>;
    public var constructor:FuncStatement;

    public function new(name:String, properties:Array<Statement>, methods:Array<Statement>, constructor:FuncStatement) {
        this.name = name;
        this.properties = properties;
        this.methods = methods;
        this.constructor = constructor;
    }

    public override function execute():Void {
        var classObj:Dynamic = {};

        var initProperties = function(instance:Dynamic):Void {
            for (property in properties) {
                property.execute();
                var letProperty:LetStatement = cast property;
                var propertyName:String = letProperty.name;
                var propertyValue:Dynamic = Environment.get(propertyName);
                Reflect.setField(instance, propertyName, propertyValue);
            }
        };

        for (method in methods) {
            method.execute();
            var funcMethod:FuncStatement = cast method;
            var methodName:String = funcMethod.name;
            var methodFunc:Function = Environment.getFunction(methodName);
            Reflect.setField(classObj, methodName, methodFunc);
        }

        if (constructor != null) {
            var constructorFunc = function(instance:Dynamic, args:Array<Dynamic>):Void {
                initProperties(instance);
                for (i in 0...args.length) {
                    Environment.define(cast(constructor, FuncStatement).parameters[i].name, args[i]);
                }
                cast(constructor, FuncStatement).execute();
            };
            Reflect.setField(classObj, "constructor", constructorFunc);
        } else {
            Reflect.setField(classObj, "constructor", initProperties);
        }

        Environment.define(name, classObj);
    }
}

class NewStatement extends Statement {
    public var className:String;
    public var arguments:Array<Expression>;

    public function new(className:String, arguments:Array<Expression>) {
        this.className = className;
        this.arguments = arguments;
    }

    public override function execute():Void {
        var classObj:Dynamic = Environment.get(className);
        if (classObj == null) {
            Flow.error.report("Undefined class: " + className);
            return;
        }

        var instance:Dynamic = {};

        var args:Array<Dynamic> = [];
        for (arg in arguments) {
            args.push(arg.evaluate());
        }

        var constructorFunc:Dynamic = Reflect.field(classObj, "constructor");
        if (constructorFunc != null) {
            constructorFunc(instance, args);
        }

        for (field in Reflect.fields(classObj)) {
            if (field != "constructor") {
                Reflect.setField(instance, field, Reflect.field(classObj, field));
            }
        }

        Environment.define("this", instance);
    }
}

class NewExpression extends Expression {
    public var className:String;
    public var arguments:Array<Expression>;

    public function new(className:String, arguments:Array<Expression>) {
        this.className = className;
        this.arguments = arguments;
    }

    public override function evaluate():Dynamic {
        var classObj:Dynamic = Environment.get(className);
        if (classObj == null) {
            Flow.error.report("Undefined class: " + className);
            return null;
        }

        var instance:Dynamic = {};

        var args:Array<Dynamic> = [];
        for (arg in arguments) {
            args.push(arg.evaluate());
        }

        var constructorFunc:Dynamic = Reflect.field(classObj, "constructor");
        if (constructorFunc != null) {
            constructorFunc(instance, args);
        }

        for (field in Reflect.fields(classObj)) {
            if (field != "constructor") {
                Reflect.setField(instance, field, Reflect.field(classObj, field));
            }
        }

        return instance;
    }
}

class DoWhileStatement extends Statement {
    public var condition:Expression;
    public var body:Statement;

    public function new(condition:Expression, body:Statement) {
        this.condition = condition;
        this.body = body;
    }

    public override function execute():Void {
        do {
            body.execute();
        } while (condition.evaluate());
    }
}

class ChrFunctionCall extends Expression {
    public var argument: Expression;

    public function new(argument: Expression) {
        this.argument = argument;
    }

    public override function evaluate(): Dynamic {
        var codeValue = argument.evaluate();

        if (!Std.is(codeValue, Int)) {
            Flow.error.report("Invalid type for character code.");
            return "";
        }

        var code = Std.int(codeValue);

        if (code < 0 || code > 1114111) {
            Flow.error.report("Character code out of range: " + code);
            return "";
        }

        return String.fromCharCode(code);
    }
}

class FillFunctionCall extends Expression {
    public var size:Expression;
    public var value:Expression;

    public function new(size:Expression, value:Expression) {
        this.size = size;
        this.value = value;
    }

    public override function evaluate():Dynamic {
        var sizeValue = size.evaluate();
        var valueValue = value.evaluate();

        if (Std.is(sizeValue, Int) && Std.is(valueValue, Int)) {
            var intSize = cast(sizeValue, Int);
            var intValue = cast(valueValue, Int);

            if (intSize < 0) {
                Flow.error.report("Size cannot be negative.");
                return [];
            }

            var result:Array<Dynamic> = [];
            for (i in 0...intSize) {
                result.push(intValue);
            }
            return result;
        } else {
            Flow.error.report("Arguments to 'fill' must be integers.");
            return [];
        }
    }
}

class CharAtFunctionCall extends Expression {
    public var stringExpr: Expression;
    public var indexExpr: Expression;

    public function new(stringExpr: Expression, indexExpr: Expression) {
        this.stringExpr = stringExpr;
        this.indexExpr = indexExpr;
    }

    public override function evaluate(): Dynamic {
        var strValue = stringExpr.evaluate();
        var indexValue = indexExpr.evaluate();

        if (!(strValue is String)) {
            Flow.error.report("Invalid type for string.");
            return "";
        }

        var str = cast(strValue, String);
        var index = Std.int(Std.parseFloat(indexValue));

        if (index < 0 || index >= str.length) {
            return "";
        }

        return str.charAt(index);
    }
}

class CharCodeAtFunctionCall extends Expression {
    public var stringExpr: Expression;
    public var indexExpr: Expression;

    public function new(stringExpr: Expression, indexExpr: Expression) {
        this.stringExpr = stringExpr;
        this.indexExpr = indexExpr;
    }

    public override function evaluate(): Dynamic {
        var strValue = stringExpr.evaluate();
        var indexValue = indexExpr.evaluate();

        if (!(strValue is String)) {
            Flow.error.report("Invalid type for string.");
            return null;
        }

        var str = cast(strValue, String);
        var index = Std.int(Std.parseFloat(indexValue));

        if (index < 0 || index >= str.length) {
            return 0;
        }

        return str.charCodeAt(index);
    }
}

class PushStatement extends Statement {
    public var array: Expression;
    public var value: Expression;

    public function new(array: Expression, value: Expression) {
        this.array = array;
        this.value = value;
    }

    public override function execute(): Void {
        var arrayValue: Array<Dynamic> = array.evaluate();
        var valueEvaluated: Dynamic = value.evaluate();

        if (arrayValue == null) {
            Flow.error.report("Cannot push to null array");
            return;
        }

        arrayValue.push(valueEvaluated);
    }
}

class PopStatement extends Statement {
    public var array: Expression;
    public var variable: String;

    public function new(array: Expression, variable: String) {
        this.array = array;
        this.variable = variable;
    }

    public override function execute(): Void {
        var arrayValue: Array<Dynamic> = array.evaluate();

        if (arrayValue == null) {
            Flow.error.report("Cannot pop from null array");
            return;
        }

        if (arrayValue.length == 0) {
            Flow.error.report("Cannot pop from empty array");
            return;
        }

        var poppedValue: Dynamic = arrayValue.pop();
        Environment.define(variable, poppedValue);
    }
}

class RemoveStatement extends Statement {
    public var array: Expression;
    public var element: Expression;
    public var variable: String;

    public function new(array: Expression, element: Expression, variable: String) {
        this.array = array;
        this.element = element;
        this.variable = variable;
    }

    public override function execute(): Void {
        var arrayValue: Array<Dynamic> = array.evaluate();
        var elementValue: Dynamic = element.evaluate();

        if (arrayValue == null) {
            Flow.error.report("Cannot remove from null array");
            return;
        }

        var index = arrayValue.indexOf(elementValue);
        if (index == -1) {
            Flow.error.report("Element not found in array");
            return;
        }

        var removedValue: Dynamic = arrayValue.splice(index, 1)[0];
        Environment.define(variable, removedValue);
    }
}

class PushFunctionCall extends Expression {
    public var array: Expression;
    public var value: Expression;

    public function new(array: Expression, value: Expression) {
        this.array = array;
        this.value = value;
    }

    public override function evaluate(): Dynamic {
        var arrayValue: Array<Dynamic> = array.evaluate();
        var valueEvaluated: Dynamic = value.evaluate();

        if (arrayValue == null) {
            Flow.error.report("Cannot push to null array");
            return null;
        }

        arrayValue.push(valueEvaluated);
        return valueEvaluated;
    }
}

class PopFunctionCall extends Expression {
    public var array: Expression;
    public var value: String;

    public function new(array: Expression, value: String) {
        this.array = array;
        this.value = value;
    }

    public override function evaluate(): Dynamic {
        var arrayValue: Array<Dynamic> = array.evaluate();

        if (arrayValue == null) {
            Flow.error.report("Cannot pop from null array");
            return null;
        }

        if (arrayValue.length == 0) {
            Flow.error.report("Cannot pop from empty array");
            return null;
        }

        var poppedValue: Dynamic = arrayValue.pop();
        Environment.define(value, poppedValue);

        return poppedValue;
    }
}

class RemoveFunctionCall extends Expression {
    public var array: Expression;
    public var element: Expression;
    public var value: String;

    public function new(array: Expression, element: Expression, value: String) {
        this.array = array;
        this.element = element;
        this.value = value;
    }

    public override function evaluate(): Dynamic {
        var arrayValue: Array<Dynamic> = array.evaluate();
        var elementValue: Dynamic = element.evaluate();

        if (arrayValue == null) {
            Flow.error.report("Cannot remove from null array");
            return null;
        }

        var index = arrayValue.indexOf(elementValue);
        if (index == -1) {
            Flow.error.report("Element not found in array");
            return null;
        }

        var removedValue: Dynamic = arrayValue.splice(index, 1)[0];
        Environment.define(value, removedValue);

        return removedValue;
    }
}

class StrFunctionCall extends Expression {
    public var argument: Expression;

    public function new(argument: Expression) {
        this.argument = argument;
    }

    public override function evaluate(): Dynamic {
        var value = argument.evaluate();
        return Std.string(value);
    }
}

class SubstringFunctionCall extends Expression {
    public var stringExpr: Expression;
    public var startExpr: Expression;
    public var endExpr: Expression;

    public function new(stringExpr: Expression, startExpr: Expression, endExpr: Expression = null) {
        this.stringExpr = stringExpr;
        this.startExpr = startExpr;
        this.endExpr = endExpr;
    }

    public override function evaluate(): Dynamic {
        var strValue = stringExpr.evaluate();
        var startValue = startExpr.evaluate();
        var str = cast(strValue, String);
        var start = Std.int(startValue);

        var end = endExpr != null ? Std.int(endExpr.evaluate()) : str.length;
        
        if (start < 0 || start > str.length || end < 0 || end > str.length || start > end) {
            Flow.error.report("Invalid substring range: " + start + " to " + end);
            return "";
        }

        return str.substring(start, end);
    }
}

class ToUpperCaseFunctionCall extends Expression {
    public var argument: Expression;

    public function new(argument: Expression) {
        this.argument = argument;
    }

    public override function evaluate(): Dynamic {
        var strValue = argument.evaluate();
        var str = cast(strValue, String);

        return str.toUpperCase();
    }
}

class ToLowerCaseFunctionCall extends Expression {
    public var argument: Expression;

    public function new(argument: Expression) {
        this.argument = argument;
    }

    public override function evaluate(): Dynamic {
        var strValue = argument.evaluate();
        var str = cast(strValue, String);

        return str.toLowerCase();
    }
}

class JoinFunctionCall extends Expression {
    public var arrayExpr: Expression;
    public var delimiterExpr: Expression;

    public function new(arrayExpr: Expression, delimiterExpr: Expression = null) {
        this.arrayExpr = arrayExpr;
        this.delimiterExpr = delimiterExpr;
    }

    public override function evaluate(): Dynamic {
        var arrayValue = arrayExpr.evaluate();
        var array = cast(arrayValue, Array<Dynamic>);

        var delimiter = delimiterExpr != null ? cast(delimiterExpr.evaluate(), String) : "";
        
        return array.join(delimiter);
    }
}

class SplitFunctionCall extends Expression {
    public var stringExpr: Expression;
    public var delimiterExpr: Expression;

    public function new(stringExpr: Expression, delimiterExpr: Expression) {
        this.stringExpr = stringExpr;
        this.delimiterExpr = delimiterExpr;
    }

    public override function evaluate(): Dynamic {
        var strValue = stringExpr.evaluate();
        var delimiterValue = delimiterExpr.evaluate();

        var str = cast(strValue, String);
        var delimiter = cast(delimiterValue, String);

        return str.split(delimiter);
    }
}

class ParseNumberFunctionCall extends Expression {
    public var argument: Expression;

    public function new(argument: Expression) {
        this.argument = argument;
    }

    public override function evaluate(): Dynamic {
        var argValue = argument.evaluate();
        var str = cast(argValue, String);
        return Std.parseFloat(str);
    }
}

class ReplaceFunctionCall extends Expression {
    public var stringExpr: Expression;
    public var targetExpr: Expression;
    public var replacementExpr: Expression;

    public function new(stringExpr: Expression, targetExpr: Expression, replacementExpr: Expression) {
        this.stringExpr = stringExpr;
        this.targetExpr = targetExpr;
        this.replacementExpr = replacementExpr;
    }

    public override function evaluate(): Dynamic {
        var strValue = stringExpr.evaluate();
        var targetValue = targetExpr.evaluate();
        var replacementValue = replacementExpr.evaluate();

        var str = cast(strValue, String);
        var target = cast(targetValue, String);
        var replacement = cast(replacementValue, String);

        return str.split(target).join(replacement);
    }
}

class ConcatFunctionCall extends Expression {
    public var firstExpr: Expression;
    public var secondExpr: Expression;

    public function new(firstExpr: Expression, secondExpr: Expression) {
        this.firstExpr = firstExpr;
        this.secondExpr = secondExpr;
    }

    public override function evaluate(): Dynamic {
        var firstValue = firstExpr.evaluate();
        var secondValue = secondExpr.evaluate();

        switch (Type.typeof(firstValue)) {
            case TClass(String):
                var firstStr = cast(firstValue, String);
                var secondStr = cast(secondValue, String);
                return firstStr + secondStr;
            case TClass(Array):
                var firstArr = cast(firstValue, Array<Dynamic>);
                var secondArr = cast(secondValue, Array<Dynamic>);
                return firstArr.concat(secondArr);
            default:
                Flow.error.report("Concat can only be applied to strings or arrays.");
                return null;
        }
    }
}

class IndexOfFunctionCall extends Expression {
    public var stringExpr: Expression;
    public var searchExpr: Expression;

    public function new(stringExpr: Expression, searchExpr: Expression) {
        this.stringExpr = stringExpr;
        this.searchExpr = searchExpr;
    }

    public override function evaluate(): Dynamic {
        var strValue = stringExpr.evaluate();
        var searchValue = searchExpr.evaluate();

        switch (Type.typeof(strValue)) {
            case TClass(String):
                var str = cast(strValue, String);
                var search = cast(searchValue, String);
                return str.indexOf(search);
            case TClass(Array):
                var arr = cast(strValue, Array<Dynamic>);
                var searchItem = searchValue;
                return arr.indexOf(searchItem);
            default:
                Flow.error.report("IndexOf can only be applied to strings or arrays.");
                return null;
        }
    }
}

class ToStringFunctionCall extends Expression {
    public var argument: Expression;

    public function new(argument: Expression) {
        this.argument = argument;
    }

    public override function evaluate(): Dynamic {
        var argValue = argument.evaluate();
        return Std.string(argValue);
    }
}

class TrimFunctionCall extends Expression {
    public var argument: Expression;

    public function new(argument: Expression) {
        this.argument = argument;
    }

    public override function evaluate(): Dynamic {
        var argValue = argument.evaluate();
        var arg = cast(argValue, String);
        return arg.trim();
    }
}

class StartsWithFunctionCall extends Expression {
    public var stringOrArrayExpr: Expression;
    public var searchExpr: Expression;

    public function new(stringOrArrayExpr: Expression, searchExpr: Expression) {
        this.stringOrArrayExpr = stringOrArrayExpr;
        this.searchExpr = searchExpr;
    }

    public override function evaluate(): Dynamic {
        var strOrArrValue = stringOrArrayExpr.evaluate();
        var searchValue = searchExpr.evaluate();

        switch (Type.typeof(strOrArrValue)) {
            case TClass(String):
                var str = cast(strOrArrValue, String);
                var searchStr = cast(searchValue, String);
                return str.indexOf(searchStr) == 0;
            case TClass(Array):
                var arr = cast(strOrArrValue, Array<Dynamic>);
                return arr.length > 0 && arr[0] == searchValue;
            default:
                Flow.error.report("StartsWith can only be applied to strings or arrays.");
                return null;
        }
    }
}

class EndsWithFunctionCall extends Expression {
    public var stringOrArrayExpr: Expression;
    public var searchExpr: Expression;

    public function new(stringOrArrayExpr: Expression, searchExpr: Expression) {
        this.stringOrArrayExpr = stringOrArrayExpr;
        this.searchExpr = searchExpr;
    }

    public override function evaluate(): Dynamic {
        var strOrArrValue = stringOrArrayExpr.evaluate();
        var searchValue = searchExpr.evaluate();

        switch (Type.typeof(strOrArrValue)) {
            case TClass(String):
                var str = cast(strOrArrValue, String);
                var searchStr = cast(searchValue, String);
                return str.lastIndexOf(searchStr) == str.length - searchStr.length;
            case TClass(Array):
                var arr = cast(strOrArrValue, Array<Dynamic>);
                return arr.length > 0 && arr[arr.length - 1] == searchValue;
            default:
                Flow.error.report("EndsWith can only be applied to strings or arrays.");
                return null;
        }
    }
}

class SliceFunctionCall extends Expression {
    public var stringOrArrayExpr: Expression;
    public var startExpr: Expression;
    public var endExpr: Expression;

    public function new(stringOrArrayExpr: Expression, startExpr: Expression, endExpr: Expression) {
        this.stringOrArrayExpr = stringOrArrayExpr;
        this.startExpr = startExpr;
        this.endExpr = endExpr;
    }

    public override function evaluate(): Dynamic {
        var strOrArrValue = stringOrArrayExpr.evaluate();
        var startValue = startExpr.evaluate();
        var endValue = endExpr.evaluate();

        var start = cast(startValue, Int);
        var end = cast(endValue, Int);

        switch (Type.typeof(strOrArrValue)) {
            case TClass(String):
                var str = cast(strOrArrValue, String);
                return str.substring(start, end);
            case TClass(Array):
                var arr = cast(strOrArrValue, Array<Dynamic>);
                return arr.slice(start, end);
            default:
                Flow.error.report("Slice can only be applied to strings or arrays.");
                return null;
        }
    }
}

class SetFunctionCall extends Expression {
    public var targetExpr: Expression;
    public var keyExpr: Expression;
    public var valueExpr: Expression;

    public function new(targetExpr: Expression, keyExpr: Expression, valueExpr: Expression) {
        this.targetExpr = targetExpr;
        this.keyExpr = keyExpr;
        this.valueExpr = valueExpr;
    }

    public override function evaluate(): Dynamic {
        var targetValue = targetExpr.evaluate();
        var keyValue = keyExpr.evaluate();
        var valueValue = valueExpr.evaluate();

        switch (Type.typeof(targetValue)) {
            case TClass(Array):
                var arr = cast(targetValue, Array<Dynamic>);
                if (Std.is(keyValue, Int)) {
                    var index = cast(keyValue, Int);
                    arr[index] = valueValue;
                } else {
                    var key = cast(keyValue, String);
                    for (i in 0...arr.length) {
                        if (arr[i][0] == key) {
                            arr[i][1] = valueValue;
                            return valueValue;
                        }
                    }
                    arr.push([key, valueValue]);
                }
                return valueValue;
            case TObject:
                Reflect.setField(targetValue, cast(keyValue, String), valueValue);
                return valueValue;
            default:
                Flow.error.report("Set can only be applied to arrays or objects.");
                return null;
        }
    }
}

class GetFunctionCall extends Expression {
    public var targetExpr: Expression;
    public var keyExpr: Expression;

    public function new(targetExpr: Expression, keyExpr: Expression) {
        this.targetExpr = targetExpr;
        this.keyExpr = keyExpr;
    }

    public override function evaluate(): Dynamic {
        var targetValue = targetExpr.evaluate();
        var keyValue = keyExpr.evaluate();

        switch (Type.typeof(targetValue)) {
            case TClass(Array):
                var arr = cast(targetValue, Array<Dynamic>);
                if (Std.is(keyValue, Int)) {
                    var index = cast(keyValue, Int);
                    return arr[index];
                } else {
                    var key = cast(keyValue, String);
                    for (i in 0...arr.length) {
                        if (arr[i][0] == key) {
                            return arr[i][1];
                        }
                    }
                    return null;
                }
            case TObject:
                return Reflect.field(targetValue, cast(keyValue, String));
            default:
                Flow.error.report("Get can only be applied to arrays or objects.");
                return null;
        }
    }
}

class SetStatement extends Statement {
    public var targetExpr: Expression;
    public var keyExpr: Expression;
    public var valueExpr: Expression;

    public function new(targetExpr: Expression, keyExpr: Expression, valueExpr: Expression) {
        this.targetExpr = targetExpr;
        this.keyExpr = keyExpr;
        this.valueExpr = valueExpr;
    }

    public override function execute():Void {
        var targetValue = targetExpr.evaluate();
        var keyValue = keyExpr.evaluate();
        var valueValue = valueExpr.evaluate();

        switch (Type.typeof(targetValue)) {
            case TClass(Array):
                var arr = cast(targetValue, Array<Dynamic>);
                if (Std.is(keyValue, Int)) {
                    var index = cast(keyValue, Int);
                    arr[index] = valueValue;
                } else {
                    var key = cast(keyValue, String);
                    var found = false;
                    for (i in 0...arr.length) {
                        if (arr[i][0] == key) {
                            arr[i][1] = valueValue;
                            found = true;
                            break;
                        }
                    }
                    if (!found) {
                        arr.push([key, valueValue]);
                    }
                }
            case TObject:
                Reflect.setField(targetValue, cast(keyValue, String), valueValue);
            default:
                Flow.error.report("Set can only be applied to arrays or objects.");
        }
    }
}

class GetStatement extends Statement {
    public var targetExpr: Expression;
    public var keyExpr: Expression;
    public var result: Dynamic;

    public function new(targetExpr: Expression, keyExpr: Expression) {
        this.targetExpr = targetExpr;
        this.keyExpr = keyExpr;
    }

    public override function execute():Void {
        var targetValue = targetExpr.evaluate();
        var keyValue = keyExpr.evaluate();

        switch (Type.typeof(targetValue)) {
            case TClass(Array):
                var arr = cast(targetValue, Array<Dynamic>);
                if (Std.is(keyValue, Int)) {
                    var index = cast(keyValue, Int);
                    if (index >= 0 && index < arr.length) {
                        result = arr[index];
                    } else {
                        result = null;
                    }
                } else {
                    var key = cast(keyValue, String);
                    for (i in 0...arr.length) {
                        if (arr[i][0] == key) {
                            result = arr[i][1];
                            return;
                        }
                    }
                    result = null;
                }
            case TObject:
                result = Reflect.field(targetValue, cast(keyValue, String));
            default:
                Flow.error.report("Get can only be applied to arrays or objects.");
        }
    }
}

class ExistsFunctionCall extends Expression {
    public var targetExpr: Expression;
    public var keyExpr: Expression;

    public function new(targetExpr: Expression, keyExpr: Expression) {
        this.targetExpr = targetExpr;
        this.keyExpr = keyExpr;
    }

    public override function evaluate(): Bool {
        var targetValue = targetExpr.evaluate();
        var keyValue = keyExpr.evaluate();

        switch (Type.typeof(targetValue)) {
            case TClass(Array):
                var arr = cast(targetValue, Array<Dynamic>);
                if (Std.is(keyValue, Int)) {
                    var index = cast(keyValue, Int);
                    return index >= 0 && index < arr.length;
                } else {
                    var key = cast(keyValue, String);
                    for (i in 0...arr.length) {
                        if (arr[i][0] == key) {
                            return true;
                        }
                    }
                    return false;
                }
            case TObject:
                return Reflect.hasField(targetValue, cast(keyValue, String));
            default:
                Flow.error.report("Exists can only be applied to arrays or objects.");
                return false;
        }
    }
}

class ExistsStatement extends Statement {
    public var targetExpr: Expression;
    public var keyExpr: Expression;
    public var result: Bool;

    public function new(targetExpr: Expression, keyExpr: Expression) {
        this.targetExpr = targetExpr;
        this.keyExpr = keyExpr;
    }

    public override function execute():Void {
        var targetValue = targetExpr.evaluate();
        var keyValue = keyExpr.evaluate();

        switch (Type.typeof(targetValue)) {
            case TClass(Array):
                var arr = cast(targetValue, Array<Dynamic>);
                if (Std.is(keyValue, Int)) {
                    var index = cast(keyValue, Int);
                    result = index >= 0 && index < arr.length;
                } else {
                    var key = cast(keyValue, String);
                    result = false;
                    for (i in 0...arr.length) {
                        if (arr[i][0] == key) {
                            result = true;
                            break;
                        }
                    }
                }
            case TObject:
                result = Reflect.hasField(targetValue, cast(keyValue, String));
            default:
                Flow.error.report("Exists can only be applied to arrays or objects.");
        }
    }
}

class SortFunctionCall extends Expression {
    public var arrayExpr: Expression;

    public function new(arrayExpr: Expression) {
        this.arrayExpr = arrayExpr;
    }

    public override function evaluate(): Dynamic {
        var arrayValue = arrayExpr.evaluate();
        if (Std.is(arrayValue, Array)) {
            var array = cast(arrayValue, Array<Dynamic>);
            array.sort(function(a: Dynamic, b: Dynamic): Int {
                if (Std.is(a, String) && Std.is(b, String)) {
                    return (a < b ? -1 : (a > b ? 1 : 0));
                } else if (Std.is(a, Int) && Std.is(b, Int)) {
                    return cast(a, Int) - cast(b, Int);
                } else if (Std.is(a, Float) && Std.is(b, Float)) {
                    return std.Math.floor(cast(a, Float) - cast(b, Float));
                } else if (Std.is(a, Float) && Std.is(b, Int)) {
                    return std.Math.floor(cast(a, Float) - cast(b, Int));
                } else if (Std.is(a, Int) && Std.is(b, Float)) {
                    return std.Math.floor(cast(a, Int) - cast(b, Float));
                } else {
                    Flow.error.report("Array contains mixed or unsupported types");
                    return 0;
                }
            });
            return array;
        } else {
            Flow.error.report("Sort function expects an array");
            return null;
        }
    }
}

class SortStatement extends Statement {
    public var arrayExpr: Expression;

    public function new(arrayExpr: Expression) {
        this.arrayExpr = arrayExpr;
    }

    public override function execute():Void {
        var arrayValue = arrayExpr.evaluate();
        if (Std.is(arrayValue, Array)) {
            var array = cast(arrayValue, Array<Dynamic>);
            array.sort(function(a: Dynamic, b: Dynamic): Int {
                if (Std.is(a, String) && Std.is(b, String)) {
                    return (a < b ? -1 : (a > b ? 1 : 0));
                } else if (Std.is(a, Int) && Std.is(b, Int)) {
                    return cast(a, Int) - cast(b, Int);
                } else if (Std.is(a, Float) && Std.is(b, Float)) {
                    return std.Math.floor(cast(a, Float) - cast(b, Float));
                } else if (Std.is(a, Float) && Std.is(b, Int)) {
                    return std.Math.floor(cast(a, Float) - cast(b, Int));
                } else if (Std.is(a, Int) && Std.is(b, Float)) {
                    return std.Math.floor(cast(a, Int) - cast(b, Float));
                } else {
                    Flow.error.report("Array contains mixed or unsupported types");
                    return 0;
                }
            });
        } else {
            Flow.error.report("Sort function expects an array");
        }
    }
}

class CapitalizeFunctionCall extends Expression {
    public var argument: Expression;

    public function new(argument: Expression) {
        this.argument = argument;
    }

    public override function evaluate(): Dynamic {
        var argValue = argument.evaluate();
        var strValue = Std.string(argValue);

        if (strValue.length > 0) {
            return strValue.charAt(0).toUpperCase() + strValue.substr(1);
        } else {
            return strValue;
        }
    }
}

class CountFunctionCall extends Expression {
    public var firstArgument: Expression;
    public var secondArgument: Expression;

    public function new(firstArgument: Expression, secondArgument: Expression) {
        this.firstArgument = firstArgument;
        this.secondArgument = secondArgument;
    }

    override function evaluate(): Dynamic {
        var arg = this.firstArgument.evaluate();
        var target = this.secondArgument.evaluate();
        
        if (Std.is(arg, String)) {
            return countOccurrencesInString(cast(arg, String), cast(target, String));
        } else if (Std.is(arg, Array)) {
            return countOccurrencesInList(cast(arg, Array<Dynamic>), target);
        } else {
            Flow.error.report("Unsupported type for count function");
            return null;
        }
    }

    function countOccurrencesInString(text: String, target: String): Int {
        var count = 0;
        var idx = 0;
        while ((idx = text.indexOf(target, idx)) != -1) {
            count++;
            idx += target.length;
        }
        return count;
    }

    function countOccurrencesInList(list: Array<Dynamic>, target: Dynamic): Int {
        var count = 0;
        for (item in list) {
            if (item == target) {
                count++;
            }
        }
        return count;
    }
}

class SpliceStatement extends Statement {
    public var array: Expression;
    public var startIndex: Expression;
    public var deleteCount: Expression;

    public function new(array: Expression, startIndex: Expression, deleteCount: Expression) {
        this.array = array;
        this.startIndex = startIndex;
        this.deleteCount = deleteCount;
    }

    public override function execute(): Void {
        var arrayValue: Array<Dynamic> = array.evaluate();
        var startIndexEvaluated: Int = startIndex.evaluate();
        var deleteCountEvaluated: Int = deleteCount.evaluate();

        if (arrayValue == null) {
            Flow.error.report("Cannot splice on null array");
            return;
        }

        if (startIndexEvaluated < 0 || startIndexEvaluated > arrayValue.length) {
            Flow.error.report("Start index out of bounds");
            return;
        }

        if (deleteCountEvaluated < 0) {
            Flow.error.report("Delete count cannot be negative");
            return;
        }

        arrayValue.splice(startIndexEvaluated, deleteCountEvaluated);
    }
}

class ReverseFunctionCall extends Expression {
    public var argument: Expression;

    public function new(argument: Expression) {
        this.argument = argument;
    }

    public override function evaluate(): Dynamic {
        var argValue = argument.evaluate();
        if (Std.is(argValue, String)) {
            var str = cast(argValue, String);
            var chars = str.split("");
            chars.reverse();
            return chars.join("");
        } else if (Std.is(argValue, Array)) {
            var array = cast(argValue, Array<Dynamic>);
            var reversedArray: Array<Dynamic> = [];
            for (i in 0...array.length) {
                reversedArray.push(array[array.length - 1 - i]);
            }
            return reversedArray;
        } else {
            Flow.error.report("Argument to 'reverse' must be either a String or an Array.");
            return null;
        }
    }
}

class IsDigitFunctionCall extends Expression {
    public var argument: Expression;

    public function new(argument: Expression) {
        this.argument = argument;
    }

    public override function evaluate(): Bool {
        var argValue = argument.evaluate();
        var arg = cast(argValue, String);
        return isDigit(arg);
    }

	private function isDigit(c:String):Bool {
		return ~/[0-9]/.match(c);
	}
}

class IsNumericFunctionCall extends Expression {
    public var argument: Expression;

    public function new(argument: Expression) {
        this.argument = argument;
    }

    public override function evaluate(): Bool {
        var argValue = argument.evaluate();
        if (Std.is(argValue, String)) {
            var str = cast(argValue, String);
            return isNumeric(str);
        } else {
            Flow.error.report("Argument to 'isNumeric' must be a string.");
            return false;
        }
    }

    public function isNumeric(value:String):Bool {
        return Std.parseInt(value) != null || value == ".";
    }
}

class CenterFunctionCall extends Expression {
    public var argument: Expression;
    public var width: Expression;
    public var fillChar: Expression;

    public function new(argument: Expression, width: Expression, fillChar: Expression = null) {
        this.argument = argument;
        this.width = width;
        this.fillChar = fillChar;
    }

    public override function evaluate(): Dynamic {
        var strValue = argument.evaluate();
        var widthValue = width.evaluate();
        var fillCharValue = fillChar != null ? fillChar.evaluate() : " ";

        if (Std.is(strValue, String) && Std.is(widthValue, Int) && Std.is(fillCharValue, String)) {
            var str = cast(strValue, String);
            var widthInt = cast(widthValue, Int);
            var fill = cast(fillCharValue, String);

            if (fill.length != 1) {
                Flow.error.report("Fill character must be a single character.");
                return str;
            }

            return centerString(str, widthInt, fill);
        } else {
            Flow.error.report("Invalid arguments to 'center'. Expected a string, integer width, and optional fill character.");
            return null;
        }
    }

    public function centerString(value:String, width:Int, fill:String):String {
        if (value.length >= width) {
            return value;
        }

        if (fill.length == 0) {
            fill = " ";
        } else if (fill.length > 1) {
            fill = fill.substr(0, 1);
        }

        var padding = width - value.length;
        var leftPad = Std.int(padding / 2);
        var rightPad = padding - leftPad;

        return StringTools.lpad(StringTools.rpad(value, fill, value.length + rightPad), fill, width);
    }
}

class CalculateFunctionCall extends Expression {
    public var argument: Expression;

    public function new(argument: Expression) {
        this.argument = argument;
    }

    public override function evaluate(): Dynamic {
        var expression = argument.evaluate();
        try {
            var tokens = tokenize(expression);
            var result = evaluateExpression(tokens);
            return result;
        } catch (e:Dynamic) {
            Flow.error.report("Invalid expression");
            return null;
        }
    }

    static function tokenize(expression:String):Array<String> {
        expression = expression.replace(" ", "");
        var tokens:Array<String> = [];
        var currentToken:String = "";

        for (i in 0...expression.length) {
            var char = expression.charAt(i);

            if (char == "+" || char == "-" || char == "*" || char == "/") {
                if (currentToken.length > 0) {
                    tokens.push(currentToken);
                    currentToken = "";
                }
                tokens.push(char);
            } else {
                currentToken += char;
            }
        }

        if (currentToken.length > 0) {
            tokens.push(currentToken);
        }

        return tokens;
    }

    static function evaluateExpression(tokens:Array<String>):Float {
        var values = new List<Float>();
        var operators = new List<String>();

        var precedence = function(op:String):Int {
            switch (op) {
                case "+", "-": return 1;
                case "*", "/": return 2;
                default: return 0;
            }
        };

        var applyOp = function(op:String, b:Float, a:Float):Float {
            switch (op) {
                case "+": return a + b;
                case "-": return a - b;
                case "*": return a * b;
                case "/": return a / b;
                default: return 0;
            }
        };

        for (token in tokens) {
            if (token == "+" || token == "-" || token == "*" || token == "/") {
                while (operators.length > 0 && precedence(operators.last()) >= precedence(token)) {
                    var op = operators.pop();
                    var value2 = values.pop();
                    var value1 = values.pop();
                    values.push(applyOp(op, value2, value1));
                }
                operators.push(token);
            } else {
                values.push(Std.parseFloat(token));
            }
        }

        while (operators.length > 0) {
            var op = operators.pop();
            var value2 = values.pop();
            var value1 = values.pop();
            values.push(applyOp(op, value2, value1));
        }

        return values.last();
    }
}

class RepeatFunctionCall extends Expression {
    public var stringArgument: Expression;
    public var countArgument: Expression;

    public function new(stringArgument: Expression, countArgument: Expression) {
        this.stringArgument = stringArgument;
        this.countArgument = countArgument;
    }

    public override function evaluate(): Dynamic {
        var strValue = stringArgument.evaluate();
        var countValue = countArgument.evaluate();

        var str = cast(strValue, String);
        var count = cast(countValue, Int);

        var result = "";
        for (i in 0...count) {
            result += str;
        }

        return result;
    }
}

class PadStartFunctionCall extends Expression {
    public var stringExpr: Expression;
    public var lengthExpr: Expression;
    public var charExpr: Expression;

    public function new(stringExpr: Expression, lengthExpr: Expression, charExpr: Expression) {
        this.stringExpr = stringExpr;
        this.lengthExpr = lengthExpr;
        this.charExpr = charExpr;
    }

    public override function evaluate(): Dynamic {
        var strValue = stringExpr.evaluate();
        var lengthValue = lengthExpr.evaluate();
        var charValue = charExpr != null ? charExpr.evaluate() : " ";

        var str = cast(strValue, String);
        var length = cast(lengthValue, Int);
        var paddingChar = cast(charValue, String);

        if (paddingChar.length != 1) {
            Flow.error.report("Padding character must be a single character.");
        }

        var paddingLength = Std.int(Math.max(0, length - str.length));
        var padding = "";
        for (i in 0...paddingLength) {
            padding += paddingChar;
        }

        return padding + str;
    }
}

class PadEndFunctionCall extends Expression {
    public var stringExpr: Expression;
    public var lengthExpr: Expression;
    public var charExpr: Expression;

    public function new(stringExpr: Expression, lengthExpr: Expression, charExpr: Expression) {
        this.stringExpr = stringExpr;
        this.lengthExpr = lengthExpr;
        this.charExpr = charExpr;
    }

    public override function evaluate(): Dynamic {
        var strValue = stringExpr.evaluate();
        var lengthValue = lengthExpr.evaluate();
        var charValue = charExpr != null ? charExpr.evaluate() : " ";

        var str = cast(strValue, String);
        var length = cast(lengthValue, Int);
        var paddingChar = cast(charValue, String);

        if (paddingChar.length != 1) {
            Flow.error.report("Padding character must be a single character.");
        }

        var paddingLength = Std.int(Math.max(0, length - str.length));
        var padding = "";
        for (i in 0...paddingLength) {
            padding += paddingChar;
        }

        return str + padding;
    }
}

class RegexFunctionCall extends Expression {
    public var patternExpr: Expression;
    public var flagsExpr: Expression;

    public function new(patternExpr: Expression, flagsExpr: Expression) {
        this.patternExpr = patternExpr;
        this.flagsExpr = flagsExpr;
    }

    public override function evaluate(): Dynamic {
        var patternValue = patternExpr.evaluate();
        var flagsValue = flagsExpr.evaluate();

        var pattern = cast(patternValue, String);
        var flags = cast(flagsValue, String);

        return new EReg(pattern, flags);
    }
}

class RegexMatchFunctionCall extends Expression {
    public var regexExpr: Expression;
    public var stringExpr: Expression;

    public function new(regexExpr: Expression, stringExpr: Expression) {
        this.regexExpr = regexExpr;
        this.stringExpr = stringExpr;
    }

    public override function evaluate(): Dynamic {
        var regexValue = regexExpr.evaluate();
        var stringValue = stringExpr.evaluate();

        var regex = cast(regexValue, EReg);
        var str = cast(stringValue, String);

        return regex.match(str);
    }
}

class RegexReplaceFunctionCall extends Expression {
    public var regexExpr: Expression;
    public var stringExpr: Expression;
    public var replacementExpr: Expression;

    public function new(regexExpr: Expression, stringExpr: Expression, replacementExpr: Expression) {
        this.regexExpr = regexExpr;
        this.stringExpr = stringExpr;
        this.replacementExpr = replacementExpr;
    }

    public override function evaluate(): Dynamic {
        var regexValue = regexExpr.evaluate();
        var stringValue = stringExpr.evaluate();
        var replacementValue = replacementExpr.evaluate();

        var regex = cast(regexValue, EReg);
        var str = cast(stringValue, String);
        var replacement = cast(replacementValue, String);

        return regex.replace(str, replacement);
    }
}

class IsEmptyFunctionCall extends Expression {
    public var argument: Expression;

    public function new(argument: Expression) {
        this.argument = argument;
    }

    public override function evaluate(): Dynamic {
        var value = argument.evaluate();

        if (Std.is(value, String)) {
            var str = cast(value, String);
            return str.length == 0;
        } else if (Std.is(value, Array)) {
            var arr = cast(value, Array<Dynamic>);
            return arr.length == 0;
        }

        return false;
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
                return IO.readLine(evaluatedArguments.join(" "));
            case "writeByte":
                if (evaluatedArguments.length == 1) {
                    var byteValue = evaluatedArguments[0];
                    if (Std.is(byteValue, Int) && byteValue >= 0 && byteValue <= 255) {
                        IO.writeByte(byteValue);
                    } else {
                        Flow.error.report("Invalid byte value: " + byteValue);
                    }
                } else {
                    Flow.error.report("writeByte requires exactly one argument.");
                }
                return null;
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
                IO.readLine(evaluatedArguments.join(" "));
            case "writeByte":
                if (evaluatedArguments.length == 1) {
                    var byteValue = evaluatedArguments[0];
                    if (Std.is(byteValue, Int) && byteValue >= 0 && byteValue <= 255) {
                        IO.writeByte(byteValue);
                    } else {
                        Flow.error.report("Invalid byte value: " + byteValue);
                    }
                } else {
                    Flow.error.report("writeByte requires exactly one argument.");
                }
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

    public override function evaluate():Dynamic {
        switch (methodName) {
            case ".nextInt":
                if (arguments.length == 2) {
                    var min:Int = arguments[0].evaluate();
                    var max:Int = arguments[1].evaluate();
                    return Random.nextInt(min, max);
                } else {
                    Flow.error.report("Invalid number of arguments for 'nextInt'", 0);
                    return null;
                }
            case ".choice":
                if (arguments.length == 1) {
                    var listExpr:Expression = arguments[0];
                    var list:Array<Dynamic> = listExpr.evaluate();
                    return Random.choice(list);
                } else {
                    Flow.error.report("Invalid number of arguments for 'choice'", 0);
                    return null;
                }
            case ".weightedChoice":
                if (arguments.length == 2) {
                    var list:Array<Dynamic> = arguments[0].evaluate();
                    var weights:Array<Float> = arguments[1].evaluate();
                    return Random.weightedChoice(list, weights);
                } else {
                    Flow.error.report("Invalid number of arguments for 'weightedChoice'", 0);
                    return null;
                }
            case ".shuffle":
                if (arguments.length == 1) {
                    var list:Array<Dynamic> = arguments[0].evaluate();
                    return Random.shuffle(list);
                } else {
                    Flow.error.report("Invalid number of arguments for 'shuffle'", 0);
                    return null;
                }
            case ".sample":
                if (arguments.length == 2) {
                    var list:Array<Dynamic> = arguments[0].evaluate();
                    var n:Int = arguments[1].evaluate();
                    return Random.sample(list, n);
                } else {
                    Flow.error.report("Invalid number of arguments for 'sample'", 0);
                    return null;
                }
            case ".gaussian":
                if (arguments.length == 2) {
                    var mean:Float = arguments[0].evaluate();
                    var stddev:Float = arguments[1].evaluate();
                    return Random.gaussian(mean, stddev);
                } else {
                    Flow.error.report("Invalid number of arguments for 'gaussian'", 0);
                    return null;
                }
            default:
                Flow.error.report("Unknown Random method: " + methodName, 0);
                return null;
        }
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
        switch (methodName) {
            case ".nextInt":
                if (arguments.length == 2) {
                    var min:Int = arguments[0].evaluate();
                    var max:Int = arguments[1].evaluate();
                    Random.nextInt(min, max);
                } else {
                    Flow.error.report("Invalid number of arguments for 'nextInt'", 0);
                }
            case ".choice":
                if (arguments.length == 1) {
                    var listExpr:Expression = arguments[0];
                    var list:Array<Dynamic> = listExpr.evaluate();
                    Random.choice(list);
                } else {
                    Flow.error.report("Invalid number of arguments for 'choice'", 0);
                }
            case ".weightedChoice":
                if (arguments.length == 2) {
                    var list:Array<Dynamic> = arguments[0].evaluate();
                    var weights:Array<Float> = arguments[1].evaluate();
                    Random.weightedChoice(list, weights);
                } else {
                    Flow.error.report("Invalid number of arguments for 'weightedChoice'", 0);
                }
            case ".shuffle":
                if (arguments.length == 1) {
                    var list:Array<Dynamic> = arguments[0].evaluate();
                    Random.shuffle(list);
                } else {
                    Flow.error.report("Invalid number of arguments for 'shuffle'", 0);
                }
            case ".sample":
                if (arguments.length == 2) {
                    var list:Array<Dynamic> = arguments[0].evaluate();
                    var n:Int = arguments[1].evaluate();
                    Random.sample(list, n);
                } else {
                    Flow.error.report("Invalid number of arguments for 'sample'", 0);
                }
            case ".gaussian":
                if (arguments.length == 2) {
                    var mean:Float = arguments[0].evaluate();
                    var stddev:Float = arguments[1].evaluate();
                    Random.gaussian(mean, stddev);
                } else {
                    Flow.error.report("Invalid number of arguments for 'gaussian'", 0);
                }
            default:
                Flow.error.report("Unknown Random method: " + methodName, 0);
        }
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
            case "openUrl":
                if (evaluatedArguments.length > 0) {
                    System.openUrl(evaluatedArguments[0]);
                }
                return null;
            case "command":
                if (evaluatedArguments.length > 0) {
                    System.command(evaluatedArguments[0]);
                }
                return null;
            case "systemName":
                return System.systemName();
            case "args":
                return System.args();
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
            case "openUrl":
                if (evaluatedArguments.length > 0) {
                    System.openUrl(evaluatedArguments[0]);
                }
            case "command":
                if (evaluatedArguments.length > 0) {
                    System.command(evaluatedArguments[0]);
                }
            case "systemName":
                System.systemName();
            case "args":
                System.args();
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
            case "appendToFile":
                File.appendToFile(evaluatedArguments[0], evaluatedArguments[1]);
                return null;
            case "deleteFile":
                File.deleteFile(evaluatedArguments[0]);
                return null;
            case "copyFile":
                File.copyFile(evaluatedArguments[0], evaluatedArguments[1]);
                return null;
            case "renameFile":
                File.renameFile(evaluatedArguments[0], evaluatedArguments[1]);
                return null;
            case "readLines":
                return File.readLines(evaluatedArguments[0]);
            case "getFileSize":
                return File.getFileSize(evaluatedArguments[0]);
            case "listFilesInDirectory":
                return File.listFilesInDirectory(evaluatedArguments[0]);
            case "createDirectory":
                File.createDirectory(evaluatedArguments[0]);
                return null;
            case "getFileExtension":
                return File.getFileExtension(evaluatedArguments[0]);
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
            case "appendToFile":
                File.appendToFile(evaluatedArguments[0], evaluatedArguments[1]);
            case "deleteFile":
                File.deleteFile(evaluatedArguments[0]);
            case "copyFile":
                File.copyFile(evaluatedArguments[0], evaluatedArguments[1]);
            case "renameFile":
                File.renameFile(evaluatedArguments[0], evaluatedArguments[1]);
            case "readLines":
                File.readLines(evaluatedArguments[0]);
            case "getFileSize":
                File.getFileSize(evaluatedArguments[0]);
            case "listFilesInDirectory":
                File.listFilesInDirectory(evaluatedArguments[0]);
            case "createDirectory":
                File.createDirectory(evaluatedArguments[0]);
            case "getFileExtension":
                File.getFileExtension(evaluatedArguments[0]);
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

class MathExpression extends Expression {
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
            case "getPI":
                return Math.getPI();
            case "abs":
                if (evaluatedArguments.length == 1) return Math.abs(evaluatedArguments[0]);
            case "max":
                if (evaluatedArguments.length == 2) return Math.max(evaluatedArguments[0], evaluatedArguments[1]);
            case "min":
                if (evaluatedArguments.length == 2) return Math.min(evaluatedArguments[0], evaluatedArguments[1]);
            case "pow":
                if (evaluatedArguments.length == 2) return Math.pow(evaluatedArguments[0], evaluatedArguments[1]);
            case "sqrt":
                if (evaluatedArguments.length == 1) return Math.sqrt(evaluatedArguments[0]);
            case "sin":
                if (evaluatedArguments.length == 1) return Math.sin(evaluatedArguments[0]);
            case "cos":
                if (evaluatedArguments.length == 1) return Math.cos(evaluatedArguments[0]);
            case "tan":
                if (evaluatedArguments.length == 1) return Math.tan(evaluatedArguments[0]);
            case "asin":
                if (evaluatedArguments.length == 1) return Math.asin(evaluatedArguments[0]);
            case "acos":
                if (evaluatedArguments.length == 1) return Math.acos(evaluatedArguments[0]);
            case "atan":
                if (evaluatedArguments.length == 1) return Math.atan(evaluatedArguments[0]);
            case "floor":
                if (evaluatedArguments.length == 1) return Math.floor(evaluatedArguments[0]);
            case "round":
                if (evaluatedArguments.length == 1) return Math.round(evaluatedArguments[0]);
            case "ceil":
                if (evaluatedArguments.length == 1) return Math.ceil(evaluatedArguments[0]);
            case "trunc":
                if (evaluatedArguments.length == 1) return Math.trunc(evaluatedArguments[0]);
            case "random":
                return Math.random();
            default:
                Flow.error.report("Unknown method: " + methodName);
        }

        Flow.error.report("Invalid arguments for method: " + methodName);
        return null;
    }
}

class MathStatement extends Statement {
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
            case "getPI":
                Math.getPI();
            case "abs":
                if (evaluatedArguments.length == 1) Math.abs(evaluatedArguments[0]);
            case "max":
                if (evaluatedArguments.length == 2) Math.max(evaluatedArguments[0], evaluatedArguments[1]);
            case "min":
                if (evaluatedArguments.length == 2) Math.min(evaluatedArguments[0], evaluatedArguments[1]);
            case "pow":
                if (evaluatedArguments.length == 2) Math.pow(evaluatedArguments[0], evaluatedArguments[1]);
            case "sqrt":
                if (evaluatedArguments.length == 1) Math.sqrt(evaluatedArguments[0]);
            case "sin":
                if (evaluatedArguments.length == 1) Math.sin(evaluatedArguments[0]);
            case "cos":
                if (evaluatedArguments.length == 1) Math.cos(evaluatedArguments[0]);
            case "tan":
                if (evaluatedArguments.length == 1) Math.tan(evaluatedArguments[0]);
            case "asin":
                if (evaluatedArguments.length == 1) Math.asin(evaluatedArguments[0]);
            case "acos":
                if (evaluatedArguments.length == 1) Math.acos(evaluatedArguments[0]);
            case "atan":
                if (evaluatedArguments.length == 1) Math.atan(evaluatedArguments[0]);
            case "floor":
                if (evaluatedArguments.length == 1) Math.floor(evaluatedArguments[0]);
            case "round":
                if (evaluatedArguments.length == 1) Math.round(evaluatedArguments[0]);
            case "ceil":
                if (evaluatedArguments.length == 1) Math.ceil(evaluatedArguments[0]);
            case "trunc":
                if (evaluatedArguments.length == 1) Math.trunc(evaluatedArguments[0]);
            case "random":
                Math.random();
            default:
                Flow.error.report("Unknown method: " + methodName);
        }
    }
}

class HttpExpression extends Expression {
    public var methodName:String;
    public var urlExpression:Expression;

    public function new(methodName:String, urlExpression:Expression) {
        this.methodName = methodName;
        this.urlExpression = urlExpression;
    }

    public override function evaluate():Dynamic {
        var url:String = urlExpression.evaluate();
        switch (methodName) {
            case "get":
                return handleGetRequest(url);
            case "post":
                return handlePostRequest(url);
            default:
                Flow.error.report("Unknown HTTP method: " + methodName);
                return null;
        }
    }

    private function handleGetRequest(url:String):Dynamic {
        var result:Dynamic = null;
        var http = new haxe.Http(url);
        http.onData = function(response:String) {
            result = response;
        };
        http.onError = function(error:String) {
            Flow.error.report("GET request failed: " + error);
        };
        http.request(false);
        return result;
    }

    private function handlePostRequest(url:String):Dynamic {
        var result:Dynamic = null;
        var http = new haxe.Http(url);
        http.onData = function(response:String) {
            result = response;
        };
        http.onError = function(error:String) {
            Flow.error.report("POST request failed: " + error);
        };
        http.request(true);
        return result;
    }
}

class HttpStatement extends Statement {
    public var methodName:String;
    public var urlExpression:Expression;

    public function new(methodName:String, urlExpression:Expression) {
        this.methodName = methodName;
        this.urlExpression = urlExpression;
    }

    public override function execute():Void {
        var url = urlExpression.evaluate();
        if (methodName == "get") {
            var http = new haxe.Http(url);
            http.onData = function(response:String) {
                return response;
            };
            http.onError = function(error:String) {
                Flow.error.report("GET request failed: " + error);
            };
            http.request(false);
        } else if (methodName == "post") {
            var http = new haxe.Http(url);
            http.onData = function(response:String) {
                return response;
            };
            http.onError = function(error:String) {
                Flow.error.report("POST request failed: " + error);
            };
            http.request(true);
        }
    }
}

class DateExpression extends Expression {
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
            case "getCurrentDateTime":
                return DateTools.getCurrentDateTime();
            case "getCurrentDate":
                return DateTools.getCurrentDate();
            case "getCurrentTime":
                return DateTools.getCurrentTime();
            case "formatDate":
                if (evaluatedArguments.length >= 1 && Std.is(evaluatedArguments[0], Date)) {
                    var date = evaluatedArguments[0];
                    var format = evaluatedArguments.length > 1 ? Std.string(evaluatedArguments[1]) : "yyyy-MM-dd";
                    return DateTools.formatDate(date, format);
                } else {
                    Flow.error.report("formatDate requires a Date argument.");
                    return null;
                }
            case "formatTime":
                if (evaluatedArguments.length >= 1 && Std.is(evaluatedArguments[0], Date)) {
                    var date = evaluatedArguments[0];
                    var format = evaluatedArguments.length > 1 ? Std.string(evaluatedArguments[1]) : "HH:mm:ss";
                    return DateTools.formatTime(date, format);
                } else {
                    Flow.error.report("formatTime requires a Date argument.");
                    return null;
                }
            case "fromString":
                if (evaluatedArguments.length == 1) {
                    var timeStr = evaluatedArguments[0];
                    return DateTools.fromString(timeStr);
                }
                Flow.error.report("fromString requires exactly one argument.");
                return null;
            case "diffInSeconds":
                if (evaluatedArguments.length == 2 && Std.is(evaluatedArguments[0], Date) && Std.is(evaluatedArguments[1], Date)) {
                    return DateTools.diffInSeconds(evaluatedArguments[0], evaluatedArguments[1]);
                } else {
                    Flow.error.report("diffInSeconds requires two Date arguments.");
                }
        }

        return null;
    }
}

class DateStatement extends Statement {
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
            case "getCurrentDateTime":
                DateTools.getCurrentDateTime();
            case "getCurrentDate":
                DateTools.getCurrentDate();
            case "getCurrentTime":
                DateTools.getCurrentTime();
            case "formatDate":
                if (evaluatedArguments.length >= 1 && Std.is(evaluatedArguments[0], Date)) {
                    var date = evaluatedArguments[0];
                    var format = evaluatedArguments.length > 1 ? Std.string(evaluatedArguments[1]) : "yyyy-MM-dd";
                    DateTools.formatDate(date, format);
                } else {
                    Flow.error.report("formatDate requires a Date argument and optionally a format string.");
                }
            case "formatTime":
                if (evaluatedArguments.length >= 1 && Std.is(evaluatedArguments[0], Date)) {
                    var date = evaluatedArguments[0];
                    var format = evaluatedArguments.length > 1 ? Std.string(evaluatedArguments[1]) : "HH:mm:ss";
                    DateTools.formatTime(date, format);
                } else {
                    Flow.error.report("formatTime requires a Date argument and optionally a format string.");
                }
            case "diffInSeconds":
                if (evaluatedArguments.length == 2 && Std.is(evaluatedArguments[0], Date) && Std.is(evaluatedArguments[1], Date)) {
                    DateTools.diffInSeconds(evaluatedArguments[0], evaluatedArguments[1]);
                } else {
                    Flow.error.report("diffInSeconds requires two Date arguments.");
                }
        }
    }
}
