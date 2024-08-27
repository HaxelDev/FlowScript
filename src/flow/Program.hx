package flow;

import logs.*;
import modules.*;

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

        switch (opera) {
            case "=":
                Environment.define(name, value);
            case "+=":
                var existingValue: Dynamic = Environment.get(name);
                if (Std.is(existingValue, Int) || Std.is(existingValue, Float)) {
                    var newValue: Float = cast(existingValue, Float) + cast(value, Float);
                    Environment.define(name, newValue);
                } else if (Std.is(existingValue, String)) {
                    var existingString: String = cast(existingValue, String);
                    var newValue: String = existingString + cast(value, String);
                    Environment.define(name, newValue);
                } else if (existingValue == null) {
                    Environment.define(name, cast(value, String));
                } else {
                    Flow.error.report("Variable '" + name + "' is not suitable for '+=' operation");
                }
            case "-=":
                var existingValue: Dynamic = Environment.get(name);
                if (Std.is(existingValue, Int) || Std.is(existingValue, Float)) {
                    var newValue: Float = cast(existingValue, Float) - cast(value, Float);
                    Environment.define(name, newValue);
                } else if (Std.is(existingValue, String)) {
                    var existingString: String = cast(existingValue, String);
                    var newValue: String = existingString.split(cast(value, String)).join("");
                    Environment.define(name, newValue);
                } else if (existingValue == null) {
                    Flow.error.report("Variable '" + name + "' is null or not a string for '-=' operation");
                } else {
                    Flow.error.report("Variable '" + name + "' is not suitable for '-=' operation");
                }
            case "++":
                var existingValue: Dynamic = Environment.get(name);
                if (Std.is(existingValue, Int) || Std.is(existingValue, Float)) {
                    var incrementValue: Float = isPrefix ? 1 : 0;
                    var newValue: Float = cast(existingValue, Float) + incrementValue;
                    Environment.define(name, newValue);
                    if (!isPrefix) {
                        newValue += 1;
                        Environment.define(name, newValue);
                    }
                } else {
                    Flow.error.report("Variable '" + name + "' is not suitable for '++' operation");
                }
            case "--":
                var existingValue: Dynamic = Environment.get(name);
                if (Std.is(existingValue, Int) || Std.is(existingValue, Float)) {
                    var decrementValue: Float = isPrefix ? 1 : 0;
                    var newValue: Float = cast(existingValue, Float) - decrementValue;
                    Environment.define(name, newValue);
                    if (!isPrefix) {
                        newValue -= 1;
                        Environment.define(name, newValue);
                    }
                } else {
                    Flow.error.report("Variable '" + name + "' is not suitable for '--' operation");
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
            if (func == null || !(func is Function)) {
                Flow.error.report("Undefined method: " + methodName);
                return null;
            }
            return func;
        } else {
            var func: Dynamic = functions.get(name);
            if (func == null) {
                Flow.error.report("Undefined function: " + name);
                return null;
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
        var leftValue = left.evaluate();
        var rightValue = right.evaluate();

        var leftIsFloat = Std.is(leftValue, Float);
        var rightIsFloat = Std.is(rightValue, Float);
        var leftIsString = Std.is(leftValue, String);
        var rightIsString = Std.is(rightValue, String);

        if (!leftIsFloat &&!leftIsString) {
            Flow.error.report("Unsupported left operand type for operator: " + opera);
            return null;
        }
        if (!rightIsFloat &&!rightIsString) {
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
                } else if (rightValue == 0) {
                    Flow.error.report("Division by zero error");
                    return null;
                } else {
                    return leftValue / rightValue;
                }
            case "%":
                if (leftIsString || rightIsString) {
                    Flow.error.report("Unsupported operator for strings: " + opera);
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
                return leftValue!= rightValue;
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
                    return (leftValue!= 0) && (rightValue!= 0);
                }
            case "or":
                if (leftIsString || rightIsString) {
                    Flow.error.report("Unsupported operator 'or' for strings");
                    return null;
                } else {
                    return (leftValue!= 0) || (rightValue!= 0);
                }
            default:
                Flow.error.report("Unknown operator: " + opera);
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
        for (value in values) {
            Reflect.setField(enumObject, value.name, value.value.evaluate());
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
    public var constructor:Statement;

    public function new(name:String, properties:Array<Statement>, methods:Array<Statement>, constructor:Statement) {
        this.name = name;
        this.properties = properties;
        this.methods = methods;
        this.constructor = constructor;
    }

    public override function execute():Void {
        var classObj:Dynamic = {};

        for (property in properties) {
            property.execute();
            var letProperty:LetStatement = cast property;
            var propertyName:String = letProperty.name;
            var propertyValue:Dynamic = Environment.get(propertyName);
            Reflect.setField(classObj, propertyName, propertyValue);
        }

        for (method in methods) {
            method.execute();
            var funcMethod:FuncStatement = cast method;
            var methodName:String = funcMethod.name;
            var methodFunc:Function = Environment.getFunction(methodName);
            Reflect.setField(classObj, methodName, methodFunc);
        }

        if (constructor != null) {
            var constructorFunc = function(instance:Dynamic, args:Array<Dynamic>):Void {
                for (i in 0...args.length) {
                    Environment.define(cast(constructor, FuncStatement).parameters[i].name, args[i]);
                }
                cast(constructor, FuncStatement).execute();
            };
            Reflect.setField(classObj, "constructor", constructorFunc);
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

class ThisStatement extends Statement {
    public var expression:Expression;

    public function new(expression:Expression) {
        this.expression = expression;
    }

    public override function execute():Void {
        Environment.define("this", expression.evaluate());
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
                    if (list == null || list.length == 0) {
                        Flow.error.report("Empty list provided to 'choice'", 0);
                        return null;
                    }
                    var index:Int = Random.nextInt(0, list.length - 1);
                    return list[index];
                } else {
                    Flow.error.report("Invalid number of arguments for 'choice'", 0);
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
                    if (list == null || list.length == 0) {
                        Flow.error.report("Empty list provided to 'choice'", 0);
                    } else {
                        var index:Int = Random.nextInt(0, list.length - 1);
                        list[index];
                    }
                } else {
                    Flow.error.report("Invalid number of arguments for 'choice'", 0);
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
