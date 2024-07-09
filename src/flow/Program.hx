package flow;

import logs.*;

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
        Logger.log(expression.evaluate());
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
    static var values:Map<String, Dynamic> = new Map();
    static var functions:Map<String, Function> = new Map();

    static public function define(name:String, value:Dynamic):Void {
        values.set(name, value);
    }

    static public function get(name:String):Dynamic {
        if (!values.exists(name)) {
            Flow.error.report("Undefined variable: " + name);
        }
        return values.get(name);
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

    static public function callFunction(name:String, arguments:Array<Dynamic>):Void {
        if (!functions.exists(name)) {
            Flow.error.report("Undefined function: " + name);
        }
        var func = functions.get(name);
        if (func.parameters.length != arguments.length) {
            Flow.error.report("Incorrect number of arguments for function: " + name);
        }
        var oldValues:Map<String, Dynamic> = values.copy();
        for (i in 0...func.parameters.length) {
            values.set(func.parameters[i], arguments[i]);
        }
        func.body.execute();
        values = oldValues;
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

		if (leftIsFloat || rightIsFloat) {
			leftValue = leftIsFloat ? leftValue : cast(leftValue, Float);
			rightValue = rightIsFloat ? rightValue : cast(rightValue, Float);

			switch (opera) {
				case "+":
					return leftValue + rightValue;
				case "-":
					return leftValue - rightValue;
				case "*":
					return leftValue * rightValue;
				case "/":
					return leftValue / rightValue;
				case "==":
					return leftValue == rightValue;
				case "!=":
					return leftValue != rightValue;
				case ">":
					return leftValue > rightValue;
				case "<":
					return leftValue < rightValue;
				case ">=":
					return leftValue >= rightValue;
				case "<=":
					return leftValue <= rightValue;
				default:
					Flow.error.report("Unknown operator: " + opera);
					return null;
			}
		} else {
			switch (opera) {
				case "+":
					return leftValue + rightValue;
				case "-":
					return leftValue - rightValue;
				case "*":
					return leftValue * rightValue;
				case "/":
					return Math.floor(leftValue / rightValue);
				case "==":
					return leftValue == rightValue;
				case "!=":
					return leftValue != rightValue;
				case ">":
					return leftValue > rightValue;
				case "<":
					return leftValue < rightValue;
				case ">=":
					return leftValue >= rightValue;
				case "<=":
					return leftValue <= rightValue;
				default:
					Flow.error.report("Unknown operator: " + opera);
					return null;
			}
		}
	}
}

class UnaryExpression extends Expression {
    public var opera:String;
    public var right:Expression;

    public function new(opera:String, right:Expression) {
        this.opera = opera;
        this.right = right;
    }

    public override function evaluate():Dynamic {
        var value = right.evaluate();
        switch (opera) {
            case "-":
                return -value;
            case "!":
                if (Std.is(value, Bool)) {
                    return !cast(value);
                } else {
                    Flow.error.report("Logical NOT (!) operator can only be applied to boolean values.");
                    return null;
                }
            default:
                Flow.error.report("Unknown unary operator: " + opera);
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
            if (Std.is(elseBranch, IfStatement)) {
                cast(elseBranch, IfStatement).execute();
            } else {
                elseBranch.execute();
            }
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
            body.execute();
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

    public override function execute(): Void {
        var iterable:Dynamic = iterableExpression.evaluate();

        if (iterable == null) {
            Flow.error.report("Iterable expression evaluates to null");
        }

        if (Reflect.isObject(iterable) && Reflect.field(iterable, "iterator") != null) {
            var iterator:Iterator<Dynamic> = Reflect.field(iterable, "iterator")();
            while (iterator.hasNext()) {
                var item:Dynamic = iterator.next();
                Environment.define(variableName, item);
                body.execute();
            }
        } else {
            Flow.error.report("Cannot iterate over non-iterable expression");
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

    public override function evaluate():Dynamic {
        var startValue = start.evaluate();
        var endValue = end.evaluate();
        var result:Array<Int> = [];
        for (i in startValue...endValue) {
            result.push(i);
        }
        return result;
    }
}

class RangeIterator {
    private var current:Int;
    private var end:Int;

    public function new(start:Int, end:Int) {
        this.current = start - 1;
        this.end = end;
    }

    public function hasNext():Bool {
        return current < end;
    }

    public function next():Int {
        current++;
        return current;
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

class AssignExpression extends Expression {
    public var name:String;
    public var value:Expression;

    public function new(name:String, value:Expression) {
        this.name = name;
        this.value = value;
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

    public function execute(args:Array<Dynamic>):Void {
        for (i in 0...parameters.length) {
            Environment.define(parameters[i], args[i]);
        }
        body.execute();
    }
}

class CallExpression extends Expression {
    public var name:String;
    public var arguments:Array<Expression>;

    public function new(name:String, arguments:Array<Expression>) {
        this.name = name;
        this.arguments = arguments;
    }

    public override function evaluate(): Dynamic {
        var func:Dynamic = Environment.getFunction(name);
        if (func == null) {
            Flow.error.report("Undefined function: " + name);
            return null;
        }

        var args:Array<Dynamic> = [];
        for (arg in arguments) {
            args.push(arg.evaluate());
        }

        if (Std.isOfType(func, Function)) {
            return executeFunction(func, args);
        } else if (Std.isOfType(func, Dynamic -> Dynamic)) {
            return executeDynamicFunction(func, args);
        } else {
            Flow.error.report("Attempting to call a non-function: " + name);
            return null;
        }
    }

    private function executeFunction(func:Function, args:Array<Dynamic>): Dynamic {
        try {
            func.execute(args);
            return null;
        } catch (e:ReturnValue) {
            return e.value;
        } catch (e:haxe.Exception) {
            Flow.error.report("Error executing function '" + name + "': " + e.toString());
            return null;
        }
    }

    private function executeDynamicFunction(func:Dynamic -> Dynamic, args:Array<Dynamic>): Dynamic {
        try {
            return func(args);
        } catch (e:haxe.Exception) {
            Flow.error.report("Error executing function '" + name + "': " + e.toString());
            return null;
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
