package flow;

import flow.Lexer;
import flow.Program;
import logs.*;

class Parser {
    private var tokens:Array<Token>;
    private var currentTokenIndex:Int;

    public function new(tokens:Array<Token>) {
        this.tokens = tokens;
        this.currentTokenIndex = 0;
    }

    public function parse():Program {
        var statements:Array<Statement> = [];
        while (!isAtEnd()) {
            var statement:Statement = parseStatement();
            statements.push(statement);
        }
        return new Program(statements);
    }

    private function parseStatement():Statement {
        var firstTokenType:TokenType = peek().type;

        if (firstTokenType == TokenType.KEYWORD) {
            var keyword:String = advance().value;
            if (keyword == "print") {
                return parsePrintStatement();
            } else if (keyword == "let") {
                return parseLetStatement();
            } else if (keyword == "if") {
                return parseIfStatement();
            } else if (keyword == "while") {
                return parseWhileStatement();
            } else if (keyword == "for") {
                return parseForStatement();
            } else if (keyword == "func") {
                return parseFuncStatement();
            } else if (keyword == "call") {
                return parseCallStatement();
            } else if (keyword == "return") {
                return parseReturnStatement();
            } else if (keyword == "break") {
                return parseBreakStatement();
            } else if (keyword == "continue") {
                return parseContinueStatement();
            } else if (keyword == "switch") {
                return parseSwitchStatement();
            } else if (keyword == "import") {
                return parseImportStatement();
            } else if (keyword == "try") {
                return parseTryStatement();
            } else if (keyword == "error") {
                return parseErrorStatement();
            } else if (keyword == "enum") {
                return parseEnumStatement();
            } else if (keyword == "class") {
                return parseClassStatement();
            } else if (keyword == "new") {
                return parseNewStatement();
            } else if (keyword == "do") {
                return parseDoWhileStatement();
            } else {
                Flow.error.report("Unknown keyword: " + keyword, peek().lineNumber);
                return null;
            }
        } else if (firstTokenType == TokenType.IO) {
            return parseIOStatement();
        } else if (firstTokenType == TokenType.RANDOM) {
            return parseRandomStatement();
        } else if (firstTokenType == TokenType.SYSTEM) {
            return parseSystemStatement();
        } else if (firstTokenType == TokenType.FILE) {
            return parseFileStatement();
        } else if (firstTokenType == TokenType.JSON) {
            return parseJsonStatement();
        } else if (firstTokenType == TokenType.MATH) {
            return parseMathStatement();
        } else if (firstTokenType == TokenType.THIS) {
            return parseThisStatement();
        } else if (firstTokenType == TokenType.IDENTIFIER) {
            if (peekNext().type == TokenType.LBRACKET) {
                return parseArrayAssignment();
            } else {
                return parseLetStatement();
            }
        } else {
            Flow.error.report("Unexpected token: " + peek().value, peek().lineNumber);
            return null;
        }
    }

    private function parseLetStatement(): LetStatement {
        var nameToken: Token = consume(TokenType.IDENTIFIER, "Expected variable name after 'let'");
        var name: String = nameToken.value;

        var opera: String = "";
        if (match([TokenType.EQUAL, TokenType.PLUS_EQUAL, TokenType.MINUS_EQUAL])) {
            opera = previous().value;
        } else {
            Flow.error.report("Expected '=', '+=', or '-=' after variable name", peek().lineNumber);
            return null;
        }

        var initializer: Expression = parseExpression();
        return new LetStatement(name, opera, initializer);
    }

    private function parseArrayLiteral():Expression {
        consume(TokenType.LBRACKET, "Expected '[' to start array literal");

        var elements:Array<Expression> = [];
        while (!check(TokenType.RBRACKET) &&!isAtEnd()) {
            if (match([TokenType.LBRACKET])) {
                var innerElements:Array<Expression> = [];
                while (!check(TokenType.RBRACKET) &&!isAtEnd()) {
                    var element:Expression = parseExpression();
                    innerElements.push(element);
                    if (match([TokenType.COMMA])) {
                        // Consume comma
                    }
                }
                consume(TokenType.RBRACKET, "Expected ']' after inner array");
                elements.push(new ArrayLiteralExpression(innerElements));
            } else {
                var element:Expression = parseExpression();
                elements.push(element);
            }
            if (match([TokenType.COMMA])) {
                // Consume comma
            }
        }
        consume(TokenType.RBRACKET, "Expected ']' after array literal");

        return new ArrayLiteralExpression(elements);
    }

    private function parseObjectLiteral(): Expression {
        var properties: Map<String, Expression> = new Map();
        consume(TokenType.LBRACE, "Expected '{' to start object literal");
    
        while (!check(TokenType.RBRACE)) {
            var key: Token = consume(TokenType.IDENTIFIER, "Expected property name");
            consume(TokenType.COLON, "Expected ':' after property name");
    
            var value: Expression;

            var firstTokenType: TokenType = peek().type;
    
            if (firstTokenType == TokenType.KEYWORD) {
                var keyword: String = advance().value;
    
                if (keyword == "func") {
                    value = parseFunctionLiteral();
                } else {
                    Flow.error.report("Unexpected keyword: " + keyword, peek().lineNumber);
                    return null;
                }
            } else if (firstTokenType == TokenType.LBRACE) {
                value = parseObjectLiteral();
            } else if (check(TokenType.LBRACKET)) {
                value = parseArrayLiteral();
            } else {
                value = parseExpression();
            }
    
            if (value == null) {
                Flow.error.report("Failed to parse value for property: " + key.value, peek().lineNumber);
                return null;
            }
    
            properties[key.value] = value;
    
            if (match([TokenType.COMMA])) {
                // Consume comma and continue
            } else {
                break;
            }
        }

        consume(TokenType.RBRACE, "Expected '}' after object literal");
        return new ObjectExpression(properties);
    }

    private function parseFunctionLiteral():Expression {
        var parameters:Array<Parameter> = [];
        consume(TokenType.LPAREN, "Expected '(' after function keyword");
        while (!check(TokenType.RPAREN)) {
            var parameterToken:Token = consume(TokenType.IDENTIFIER, "Expected parameter name");
            var parameterName:String = parameterToken.value;
            var defaultValue:Expression = null;

            if (match([TokenType.EQUAL])) {
                defaultValue = parseExpression();
            }

            parameters.push(new Parameter(parameterName, defaultValue));

            if (match([TokenType.COMMA])) {
                // Consume comma
            }
        }
        consume(TokenType.RPAREN, "Expected ')' after parameters");

        var body:BlockStatement = parseBlock();

        return new FunctionLiteralExpression(parameters, body);
    }

    function parseThisStatement():ThisStatement {
        var expression = parseExpression();
        return new ThisStatement(expression);
    }

    private function parseArrayAssignment():Statement {
        var arrayName:String = advance().value;
        consume(TokenType.LBRACKET, "Expected '[' after array name");
        var index:Expression = parseExpression();
        consume(TokenType.RBRACKET, "Expected ']' after array index");
        consume(TokenType.EQUAL, "Expected '=' after array index");
        var value:Expression = parseExpression();
        return new ArrayAssignmentStatement(arrayName, index, value);
    }

    private function parsePrintStatement():Statement {
        consume(TokenType.LPAREN, "Expected '(' after 'print'");
        var expression:Expression = parseExpression();
        consume(TokenType.RPAREN, "Expected ')' after expression");
        return new PrintStatement(expression);
    }

    private function parseErrorStatement():Statement {
        consume(TokenType.LPAREN, "Expected '(' after 'error'");
        var expression:Expression = parseExpression();
        consume(TokenType.RPAREN, "Expected ')' after expression");
        return new ErrorStatement(expression);
    }

    private function parseIfStatement():Statement {
        var condition:Expression = parseExpression();
        var thenBranch:Statement = parseBlock();
        var elseBranch:Statement = null;

        if (match([TokenType.KEYWORD])) {
            var keyword:String = previous().value;
            if (keyword == "else") {
                if (peek().type == TokenType.KEYWORD && peek().value == "if") {
                    advance();
                    elseBranch = parseIfStatement();
                } else {
                    elseBranch = parseBlock();
                }
            }
        }

        return new IfStatement(condition, thenBranch, elseBranch);
    }

    private function parseWhileStatement():Statement {
        var condition:Expression = parseExpression();
        var body:Statement = parseBlock();
        return new WhileStatement(condition, body);
    }

    private function parseForStatement():Statement {
        var variableToken:Token = consume(TokenType.IDENTIFIER, "Expected identifier after 'for'");
        var variableName:String = variableToken.value;
    
        consume(TokenType.IN, "Expected 'in' after identifier");
    
        var iterableExpression:Expression;

        if (match([TokenType.RANGE])) {
            consume(TokenType.LPAREN, "Expected '(' after 'range'");
            var startExpr:Expression = parseExpression();
            if (match([TokenType.COMMA])) {
                // Consume comma
            }
            var endExpr:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after range expression");
    
            iterableExpression = new RangeExpression(startExpr, endExpr);
        } else {
            iterableExpression = parseExpression();
        }

        var body:Statement = parseBlock();
    
        return new ForStatement(variableName, iterableExpression, body);
    }

    private function parseFuncStatement():Statement {
        var nameToken:Token = consume(TokenType.IDENTIFIER, "Expected function name after 'func'");
        var name:String = nameToken.value;
    
        consume(TokenType.LPAREN, "Expected '(' after function name");
    
        var parameters:Array<Parameter> = [];
        while (!check(TokenType.RPAREN)) {
            var parameterToken:Token = consume(TokenType.IDENTIFIER, "Expected parameter name");
            var parameterName:String = parameterToken.value;
            var defaultValue:Expression = null;
    
            if (match([TokenType.EQUAL])) {
                defaultValue = parseExpression();
            }
    
            parameters.push(new Parameter(parameterName, defaultValue));
    
            if (match([TokenType.COMMA])) {
                // Consume comma
            }
        }
        consume(TokenType.RPAREN, "Expected ')' after parameters");
    
        var body:BlockStatement = parseBlock();
        return new FuncStatement(name, parameters, body);
    }

    private function parseCallStatement():Statement {
        var nameToken:Token = consume(TokenType.IDENTIFIER, "Expected function name after 'call'");
        var name:String = nameToken.value;
        var arguments:Array<Expression> = [];
        if (name == "push") {
            return parsePushStatement();
        } else if (name == "pop") {
            return parsePopStatement();
        } else if (name == "set") {
            return parseSetStatement();
        } else if (name == "get") {
            return parseGetStatement();
        } else if (name == "sort") {
            return parseSortStatement();
        }        
        var isMethodCall: Bool = name.indexOf(".") > -1;
        if (isMethodCall) {
            var parts: Array<String> = name.split(".");
            var objectName: String = parts.shift();
            var methodName: String = parts.join(".");

            consume(TokenType.LPAREN, "Expected '(' after method name");

            while (!check(TokenType.RPAREN)) {
                arguments.push(parseExpression());
                if (match([TokenType.COMMA])) {
                    // Consume comma
                }
            }

            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new MethodCallStatement(objectName, methodName, arguments);
        } else {
            consume(TokenType.LPAREN, "Expected '(' after function name");

            while (!check(TokenType.RPAREN)) {
                arguments.push(parseExpression());
                if (match([TokenType.COMMA])) {
                    // Consume comma
                }
            }

            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new CallStatement(name, arguments);
        }
    }

    private function parseReturnStatement(): Statement {
        var expression:Expression = parseExpression();
        return new ReturnStatement(expression);
    }

    private function parseBreakStatement():Statement {
        return new BreakStatement();
    }

    private function parseContinueStatement():Statement {
        return new ContinueStatement();
    }

    private function parseSwitchStatement():Statement {
        var expression = parseExpression();

        consume(TokenType.LBRACE, "Expected '{' before switch cases.");

        var cases:Array<CaseClause> = [];
        var defaultClause:DefaultClause = null;

        while (!check(TokenType.RBRACE) && !isAtEnd()) {
            if (match([TokenType.CASE])) {
                var caseValue = parseExpression();
                consume(TokenType.COLON, "Expected ':' after case value.");
                var caseBody = parseBlock();
                var fallsThrough = check(TokenType.CASE) || check(TokenType.DEFAULT);
                cases.push(new CaseClause(caseValue, caseBody, fallsThrough));
            } else if (match([TokenType.DEFAULT])) {
                consume(TokenType.COLON, "Expected ':' after 'default'.");
                var defaultBody = parseBlock();
                defaultClause = new DefaultClause(defaultBody);
            } else {
                Flow.error.report("Expected 'case' or 'default' in switch statement.", peek().lineNumber);
                break;
            }
        }

        consume(TokenType.RBRACE, "Expected '}' after switch cases.");

        return new SwitchStatement(expression, cases, defaultClause);
    }

    private function parseImportStatement():Statement {
        var scriptFile:Token = consume(TokenType.STRING, "Expected script file name after 'import'");
        return new ImportStatement(scriptFile.value);
    }

    private function parseTryStatement(): Statement {
        var tryBlock: BlockStatement = parseBlock();

        var catchClauses: Array<CatchClause> = [];
        while (match([TokenType.KEYWORD]) && previous().value == "catch") {
            var catchClause: CatchClause = parseCatchClause();
            catchClauses.push(catchClause);
        }

        return new TryStatement(tryBlock, catchClauses);
    }

    private function parseCatchClause(): CatchClause {
        var variableToken: Token = consume(TokenType.IDENTIFIER, "Expected variable name");
        var variableName: String = variableToken.value;
        var catchBlock: BlockStatement = parseBlock();
        return new CatchClause(variableName, catchBlock);
    }

    private function parseEnumStatement():Statement {
        var name = consume(TokenType.IDENTIFIER, "Expected enum name.").value;

        var values:Array<EnumValue> = [];
    
        if (match([TokenType.LBRACE])) {
            while (!check(TokenType.RBRACE) && !isAtEnd()) {
                var valueName = consume(TokenType.IDENTIFIER, "Expected enum value name.").value;
                var value = null;
    
                if (match([TokenType.EQUAL])) {
                    value = parseExpression();
                }
    
                values.push(new EnumValue(valueName, value));
    
                if (!match([TokenType.COMMA])) {
                    break;
                }
            }
    
            consume(TokenType.RBRACE, "Expected '}' after enum values.");
        }
    
        return new EnumStatement(name, values);
    }

    private function parseClassStatement(): Statement {
        var nameToken: Token = consume(TokenType.IDENTIFIER, "Expected class name after 'class'");
        var name: String = nameToken.value;
    
        var properties: Array<Statement> = [];
        var methods: Array<Statement> = [];
        var constructor: Statement = null;
    
        consume(TokenType.LBRACE, "Expected '{' after class name");
    
        while (!check(TokenType.RBRACE) && !isAtEnd()) {
            if (match([TokenType.KEYWORD])) {
                var keyword: String = previous().value;
                if (keyword == "let") {
                    properties.push(parseLetStatement());
                } else if (keyword == "func") {
                    var funcStatement: Statement = parseFuncStatement();
                    if (cast(funcStatement, FuncStatement).name == "constructor") {
                        constructor = funcStatement;
                    } else {
                        methods.push(funcStatement);
                    }
                } else {
                    Flow.error.report("Unexpected keyword in class: " + keyword);
                }
            } else {
                Flow.error.report("Unexpected token in class: " + peek().value);
            }
        }
    
        consume(TokenType.RBRACE, "Expected '}' after class body");
    
        return new ClassStatement(name, properties, methods, constructor);
    }

    private function parseNewStatement():Statement {
        var classNameToken:Token = consume(TokenType.IDENTIFIER, "Expected class name after 'new'");
        var className:String = classNameToken.value;
    
        consume(TokenType.LPAREN, "Expected '(' after class name");
        var arguments:Array<Expression> = [];
        while (!check(TokenType.RPAREN)) {
            arguments.push(parseExpression());
            if (match([TokenType.COMMA])) {
                // Consume comma
            }
        }
        consume(TokenType.RPAREN, "Expected ')' after arguments");
    
        return new NewStatement(className, arguments);
    }

    private function parseDoWhileStatement():Statement {
        var body:Statement = parseBlock();
    
        consume(TokenType.KEYWORD, "Expected 'while' after 'do' block");
        var whileKeyword:String = previous().value;

        if (whileKeyword != "while") {
            Flow.error.report("Expected 'while' after 'do' block");
            return null;
        }

        var condition:Expression = parseExpression();
        return new DoWhileStatement(condition, body);
    }

    private function parsePushStatement(): Statement {
        consume(TokenType.LPAREN, "Expected '(' after 'push'");
        var array: Expression = parseExpression();
        consume(TokenType.COMMA, "Expected ',' after array argument in 'push'");
        var value: Expression = parseExpression();
        consume(TokenType.RPAREN, "Expected ')' after arguments in 'push'");
        return new PushStatement(array, value);
    }

    private function parsePopStatement(): Statement {
        consume(TokenType.LPAREN, "Expected '(' after 'pop'");
        var array: Expression = parseExpression();
        consume(TokenType.COMMA, "Expected ',' after array argument in 'pop'");
        var variableToken: Token = consume(TokenType.IDENTIFIER, "Expected variable name after ','");
        consume(TokenType.RPAREN, "Expected ')' after arguments in 'pop'");
        var variable: String = variableToken.value;
        return new PopStatement(array, variable);
    }

    private function parseSetStatement(): Statement {
        consume(TokenType.LPAREN, "Expected '(' after 'set'");
        var targetExpr: Expression = parseExpression();
        consume(TokenType.COMMA, "Expected ',' after target expression in 'set'");
        var keyExpr: Expression = parseExpression();
        consume(TokenType.COMMA, "Expected ',' after key expression in 'set'");
        var valueExpr: Expression = parseExpression();
        consume(TokenType.RPAREN, "Expected ')' after value expression in 'set'");
        return new SetStatement(targetExpr, keyExpr, valueExpr);
    }

    private function parseGetStatement(): Statement {
        consume(TokenType.LPAREN, "Expected '(' after 'get'");
        var targetExpr: Expression = parseExpression();
        consume(TokenType.COMMA, "Expected ',' after target expression in 'get'");
        var keyExpr: Expression = parseExpression();
        consume(TokenType.RPAREN, "Expected ')' after key expression in 'get'");
        return new GetStatement(targetExpr, keyExpr);
    }

    private function parseSortStatement(): Statement {
        consume(TokenType.LPAREN, "Expected '(' after 'sort'");
        var arrayExpr: Expression = parseExpression();
        consume(TokenType.RPAREN, "Expected ')' after array argument in 'sort'");
        return new SortStatement(arrayExpr);
    }

    private function parseIOStatement():Statement {
        var ioToken:Token = advance();
        if (ioToken.type != TokenType.IO) {
            Flow.error.report("Expected 'IO' keyword", peek().lineNumber);
            return null;
        }
        var lparenToken:Token = advance();
        if (lparenToken.type != TokenType.LPAREN) {
            Flow.error.report("Expected '('", peek().lineNumber);
            return null;
        }
        var rparenToken:Token = advance();
        if (rparenToken.type != TokenType.RPAREN) {
            Flow.error.report("Expected ')'", peek().lineNumber);
            return null;
        }
        var methodNameToken:Token = advance();
        var methodName:String = methodNameToken.value;
        if (methodName == ".readLine") {
            consume(TokenType.LPAREN, "Expected '(' after 'readLine'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new IOStatement("readLine", [expression]);
        } else if (methodName == ".print") {
            consume(TokenType.LPAREN, "Expected '(' after 'print'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new IOStatement("print", [expression]);
        } else if (methodName == ".println") {
            consume(TokenType.LPAREN, "Expected '(' after 'println'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new IOStatement("println", [expression]);
        } else if (methodName == ".writeByte") {
            consume(TokenType.LPAREN, "Expected '(' after 'writeByte'");
            var expression: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new IOStatement("writeByte", [expression]);
        } else {
            Flow.error.report("Unknown IO method: " + methodName, peek().lineNumber);
            return null;
        }
    }

    private function parseRandomStatement():Statement {
        var randomToken:Token = advance();
        if (randomToken.type != TokenType.RANDOM) {
            Flow.error.report("Expected 'Random' keyword", peek().lineNumber);
            return null;
        }

        var lparenToken:Token = advance();
        if (lparenToken.type != TokenType.LPAREN) {
            Flow.error.report("Expected '('", peek().lineNumber);
            return null;
        }

        var rparenToken:Token = advance();
        if (rparenToken.type != TokenType.RPAREN) {
            Flow.error.report("Expected ')'", peek().lineNumber);
            return null;
        }

        var methodNameToken:Token = advance();
        var methodName:String = methodNameToken.value;

        if (methodName == ".nextInt") {
            var lparenToken:Token = advance();
            if (lparenToken.type != TokenType.LPAREN) {
                Flow.error.report("Expected '(' after 'nextInt'", peek().lineNumber);
                return null;
            }

            var minExpr:Expression = parseExpression();
            var commaToken:Token = advance();
            if (commaToken.type != TokenType.COMMA) {
                Flow.error.report("Expected ',' after min value", peek().lineNumber);
                return null;
            }

            var maxExpr:Expression = parseExpression();
            var rparenToken:Token = advance();
            if (rparenToken.type != TokenType.RPAREN) {
                Flow.error.report("Expected ')' after max value", peek().lineNumber);
                return null;
            }

            return new RandomStatement(methodName, [minExpr, maxExpr]);
        } else {
            Flow.error.report("Unknown Random method: " + methodName, peek().lineNumber);
            return null;
        }
    }

    private function parseSystemStatement():Statement {
        var systemToken:Token = advance();
        if (systemToken.type != TokenType.SYSTEM) {
            Flow.error.report("Expected 'System' keyword", peek().lineNumber);
            return null;
        }

        var lparenToken:Token = advance();
        if (lparenToken.type != TokenType.LPAREN) {
            Flow.error.report("Expected '('", peek().lineNumber);
            return null;
        }

        var rparenToken:Token = advance();
        if (rparenToken.type != TokenType.RPAREN) {
            Flow.error.report("Expected ')'", peek().lineNumber);
            return null;
        }

        var methodNameToken:Token = advance();
        var methodName:String = methodNameToken.value;

        if (methodName == ".currentDate") {
            consume(TokenType.LPAREN, "Expected '(' after 'Date'");
            consume(TokenType.RPAREN, "Expected ')' after 'Date'");
            return new SystemStatement("currentDate");
        } else if (methodName == ".exit") {
            consume(TokenType.LPAREN, "Expected '(' after 'exit'");
            consume(TokenType.RPAREN, "Expected ')' after 'exit'");
            return new SystemStatement("exit");
        } else if (methodName == ".println") {
            consume(TokenType.LPAREN, "Expected '(' after 'println'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new SystemStatement("println", [expression]);
        } else if (methodName == ".sleep") {
            consume(TokenType.LPAREN, "Expected '(' after 'sleep'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new SystemStatement("sleep", [expression]);
        } else if (methodName == ".command") {
            consume(TokenType.LPAREN, "Expected '(' after 'command'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new SystemStatement("command", [expression]);
        } else if (methodName == ".systemName") {
            consume(TokenType.LPAREN, "Expected '(' after 'systemName'");
            consume(TokenType.RPAREN, "Expected ')' after 'systemName'");
            return new SystemStatement("systemName");
        } else if (methodName == ".openUrl") {
            consume(TokenType.LPAREN, "Expected '(' after 'openUrl'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new SystemStatement("openUrl", [expression]);
        } else {
            Flow.error.report("Unknown System method: " + methodName, peek().lineNumber);
            return null;
        }
    }

    private function parseFileStatement():Statement {
        var fileToken:Token = advance();
        if (fileToken.type != TokenType.FILE) {
            Flow.error.report("Expected 'File' keyword", peek().lineNumber);
            return null;
        }

        var lparenToken:Token = advance();
        if (lparenToken.type != TokenType.LPAREN) {
            Flow.error.report("Expected '('", peek().lineNumber);
            return null;
        }

        var rparenToken:Token = advance();
        if (rparenToken.type != TokenType.RPAREN) {
            Flow.error.report("Expected ')'", peek().lineNumber);
            return null;
        }

        var methodNameToken:Token = advance();
        var methodName:String = methodNameToken.value;

        if (methodName == ".readFile") {
            consume(TokenType.LPAREN, "Expected '(' after 'readFile'");
            var filePath:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after file path expression");
            return new FileStatement("readFile", [filePath]);
        } else if (methodName == ".writeFile") {
            consume(TokenType.LPAREN, "Expected '(' after 'writeFile'");
            var filePath:Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after file path expression");
            var content:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after content expression");
            return new FileStatement("writeFile", [filePath, content]);
        } else if (methodName == ".exists") {
            consume(TokenType.LPAREN, "Expected '(' after 'exists'");
            var filePath:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after file path expression");
            return new FileStatement("exists", [filePath]);
        } else {
            Flow.error.report("Unknown File method: " + methodName, peek().lineNumber);
            return null;
        }
    }

    private function parseJsonStatement():Statement {
        var jsonToken:Token = advance();
        if (jsonToken.type != TokenType.JSON) {
            Flow.error.report("Expected 'Json' keyword", peek().lineNumber);
            return null;
        }

        var lparenToken:Token = advance();
        if (lparenToken.type != TokenType.LPAREN) {
            Flow.error.report("Expected '('", peek().lineNumber);
            return null;
        }

        var rparenToken:Token = advance();
        if (rparenToken.type != TokenType.RPAREN) {
            Flow.error.report("Expected ')'", peek().lineNumber);
            return null;
        }

        var methodNameToken:Token = advance();
        var methodName:String = methodNameToken.value;

        if (methodName == ".parse") {
            consume(TokenType.LPAREN, "Expected '(' after 'parse'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new JsonStatement("parse", [expression]);
        } else if (methodName == ".stringify") {
            consume(TokenType.LPAREN, "Expected '(' after 'stringify'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new JsonStatement("stringify", [expression]);
        } else if (methodName == ".isValid") {
            consume(TokenType.LPAREN, "Expected '(' after 'isValid'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new JsonStatement("isValid", [expression]);
        } else {
            Flow.error.report("Unknown Json method: " + methodName, peek().lineNumber);
            return null;
        }
    }

    private function parseMathStatement():Statement {
        var ioToken:Token = advance();
        if (ioToken.type != TokenType.MATH) {
            Flow.error.report("Expected 'Math' keyword", peek().lineNumber);
            return null;
        }
        var lparenToken:Token = advance();
        if (lparenToken.type != TokenType.LPAREN) {
            Flow.error.report("Expected '('", peek().lineNumber);
            return null;
        }
        var rparenToken:Token = advance();
        if (rparenToken.type != TokenType.RPAREN) {
            Flow.error.report("Expected ')'", peek().lineNumber);
            return null;
        }

        var methodNameToken:Token = advance();
        var methodName:String = methodNameToken.value;

        var methods = [
            { name: ".getPI", args: 0 },
            { name: ".abs", args: 1 },
            { name: ".max", args: 2 },
            { name: ".min", args: 2 },
            { name: ".pow", args: 2 },
            { name: ".sqrt", args: 1 },
            { name: ".sin", args: 1 },
            { name: ".cos", args: 1 },
            { name: ".tan", args: 1 },
            { name: ".asin", args: 1 },
            { name: ".acos", args: 1 },
            { name: ".atan", args: 1 }
        ];

        var methodConfig = null;
        for (method in methods) {
            if (method.name == methodName) {
                methodConfig = method;
                break;
            }
        }
    
        if (methodConfig == null) {
            Flow.error.report("Unknown Math method: " + methodName, peek().lineNumber);
            return null;
        }
    
        consume(TokenType.LPAREN, "Expected '(' after '" + methodName + "'");
    
        var arguments:Array<Expression> = [];
    
        for (i in 0...methodConfig.args) {
            if (i > 0) {
                consume(TokenType.COMMA, "Expected ',' between arguments");
            }
            arguments.push(parseExpression());
        }
    
        consume(TokenType.RPAREN, "Expected ')' after arguments");
    
        return new MathStatement(methodName.substr(1), arguments);
    }

    private function parseBlock(): BlockStatement {
        if (match([TokenType.LBRACE])) {
            var statements:Array<Statement> = [];
            while (!check(TokenType.RBRACE) && !isAtEnd()) {
                statements.push(parseStatement());
            }
            consume(TokenType.RBRACE, "Expected '}' after block");
            return new BlockStatement(statements);
        } else {
            var statement:Statement = parseStatement();
            return new BlockStatement([statement]);
        }
    }

    private function parseNewExpression():Expression {
        var classNameToken:Token = consume(TokenType.IDENTIFIER, "Expected class name after 'new'");
        var className:String = classNameToken.value;
    
        consume(TokenType.LPAREN, "Expected '(' after class name");
        var arguments:Array<Expression> = [];
        while (!check(TokenType.RPAREN)) {
            arguments.push(parseExpression());
            if (match([TokenType.COMMA])) {
                // Consume comma
            }
        }
        consume(TokenType.RPAREN, "Expected ')' after arguments");
        return new NewExpression(className, arguments);
    }

    private function parseExpression():Expression {
        var firstTokenType:TokenType = peek().type;
        if (firstTokenType == TokenType.KEYWORD) {
            var keyword:String = advance().value;
            if (keyword == "func") {
                return parseFunctionLiteral();
            } else if (keyword == "new") {
                return parseNewExpression();
            }
        } else if (firstTokenType == TokenType.LBRACKET) {
            return parseArrayLiteral();
        } else if (firstTokenType == TokenType.LBRACE) {
            return parseObjectLiteral();
        }
        return parseLogicalOr();
    }

    private function parseLogicalOr():Expression {
        var expr = parseLogicalAnd();
        while (match([TokenType.OR])) {
            var opera = previous().value;
            var right = parseLogicalAnd();
            expr = new BinaryExpression(expr, opera, right);
        }
        return expr;
    }

    private function parseLogicalAnd():Expression {
        var expr = parseEquality();
        while (match([TokenType.AND])) {
            var opera = previous().value;
            var right = parseEquality();
            expr = new BinaryExpression(expr, opera, right);
        }
        return expr;
    }

    private function parseEquality():Expression {
        var expr = parseComparison();
        while (match([TokenType.EQUAL_EQUAL, TokenType.BANG_EQUAL])) {
            var opera = previous().value;
            var right = parseComparison();
            expr = new BinaryExpression(expr, opera, right);
        }
        return expr;
    }
    
    private function parseComparison(): Expression {
        var expr: Expression = parseTerm();
        while (match([TokenType.GREATER, TokenType.GREATER_EQUAL, TokenType.LESS, TokenType.LESS_EQUAL])) {
            var opera: String = previous().value;
            var right: Expression = parseTerm();
            expr = new BinaryExpression(expr, opera, right);
        }
        return expr;
    }

    private function parseTerm(): Expression {
        var expr: Expression = parseFactor();
        while (match([TokenType.PLUS, TokenType.MINUS, TokenType.MULTIPLY, TokenType.DIVIDE, TokenType.MODULO])) {
            var opera: String = previous().value;
            var right: Expression = parseFactor();
            expr = new BinaryExpression(expr, opera, right);
        }
        return expr;
    }

    private function parseFactor():Expression {
        if (match([TokenType.NOT])) {
            return parseLogicalNot();
        } else if (match([TokenType.PLUS_PLUS, TokenType.MINUS_MINUS])) {
            var opera: String = previous().value;
            var operand: Expression = parseFactor();
            return new UnaryExpression(opera, operand, true);
        } else if (match([TokenType.NUMBER])) {
            var value:String = previous().value;
            if (value.indexOf(".") != -1) {
                return new LiteralExpression(Std.parseFloat(value));
            } else {
                return new LiteralExpression(Std.parseInt(value));
            }
        } else if (match([TokenType.STRING])) {
            return parseString();
        } else if (match([TokenType.IO])) {
            consume(TokenType.LPAREN, "Expected '('");
            consume(TokenType.RPAREN, "Expected ')'");
            return parseIOExpression();
        } else if (match([TokenType.RANDOM])) {
            consume(TokenType.LPAREN, "Expected '('");
            consume(TokenType.RPAREN, "Expected ')'");
            return parseRandomExpression();
        } else if (match([TokenType.SYSTEM])) {
            consume(TokenType.LPAREN, "Expected '('");
            consume(TokenType.RPAREN, "Expected ')'");
            return parseSystemExpression();
        } else if (match([TokenType.FILE])) {
            consume(TokenType.LPAREN, "Expected '('");
            consume(TokenType.RPAREN, "Expected ')'");
            return parseFileExpression();
        } else if (match([TokenType.JSON])) {
            consume(TokenType.LPAREN, "Expected '('");
            consume(TokenType.RPAREN, "Expected ')'");
            return parseJsonExpression();
        } else if (match([TokenType.MATH])) {
            consume(TokenType.LPAREN, "Expected '('");
            consume(TokenType.RPAREN, "Expected ')'");
            return parseMathExpression();
        } else if (match([TokenType.IDENTIFIER])) {
            var expr: Expression = null;
            if (peek().type == TokenType.LPAREN) {
                expr = parseCallExpression();
            } else if (peek().type == TokenType.LBRACKET) {
                expr = parseArrayAccess();
            } else {
                expr = parsePropertyAccess();
            }
            if (match([TokenType.PLUS_PLUS, TokenType.MINUS_MINUS])) {
                var opera: String = previous().value;
                return new UnaryExpression(opera, expr, false);
            }
            return expr;
        } else if (match([TokenType.TRUE])) {
            return new LiteralExpression(true);
        } else if (match([TokenType.FALSE])) {
            return new LiteralExpression(false);
        } else if (match([TokenType.LPAREN])) {
            var expr:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return expr;
        } else {
            Flow.error.report("Unexpected token: " + peek().value, peek().lineNumber);
            return null;
        }
    }

    private function parseString(): Expression {
        var value:String = previous().value;
        var parts:Array<Expression> = [];
        var currentPart:String = "";
        var i:Int = 0;

        while (i < value.length) {
            var char:String = value.charAt(i);

            if (char == '{') {
                if (currentPart.length > 0) {
                    parts.push(new LiteralExpression(currentPart));
                    currentPart = "";
                }

                i++;
                var varName:String = "";

                while (i < value.length && value.charAt(i) != '}') {
                    varName += value.charAt(i);
                    i++;
                }

                if (i < value.length && value.charAt(i) == '}') {
                    parts.push(new VariableExpression(varName));
                }

                currentPart = "";
            } else {
                currentPart += char;
            }

            i++;
        }

        if (currentPart.length > 0) {
            parts.push(new LiteralExpression(currentPart));
        }

        return new ConcatenationExpression(parts);
    }

    private function parseLogicalNot():Expression {
        var expr = parseLogicalAnd();
        return new UnaryExpression("not", expr, true);
    }

    private function parseIOExpression():Expression {
        var methodNameToken:Token = advance();
        var methodName:String = methodNameToken.value;
        if (methodName == ".readLine") {
            consume(TokenType.LPAREN, "Expected '(' after 'readLine'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new IOExpression("readLine", [expression]);
        } else if (methodName == ".print") {
            consume(TokenType.LPAREN, "Expected '(' after 'print'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new IOExpression("print", [expression]);
        } else if (methodName == ".println") {
            consume(TokenType.LPAREN, "Expected '(' after 'println'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new IOExpression("println", [expression]);
        } else if (methodName == ".writeByte") {
            consume(TokenType.LPAREN, "Expected '(' after 'writeByte'");
            var expression: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new IOExpression("writeByte", [expression]);
        } else {
            Flow.error.report("Unknown IO method: " + methodName, peek().lineNumber);
            return null;
        }
    }

    private function parseRandomExpression():Expression {
        var methodNameToken:Token = advance();
        var methodName:String = methodNameToken.value;

        if (methodName == ".nextInt") {
            var lparenToken:Token = advance();
            if (lparenToken.type != TokenType.LPAREN) {
                Flow.error.report("Expected '(' after 'nextInt'", peek().lineNumber);
                return null;
            }

            var minExpr:Expression = parseExpression();
            var commaToken:Token = advance();
            if (commaToken.type != TokenType.COMMA) {
                Flow.error.report("Expected ',' after min value", peek().lineNumber);
                return null;
            }

            var maxExpr:Expression = parseExpression();
            var rparenToken:Token = advance();
            if (rparenToken.type != TokenType.RPAREN) {
                Flow.error.report("Expected ')' after max value", peek().lineNumber);
                return null;
            }

            return new RandomExpression(methodName, [minExpr, maxExpr]);
        } else {
            Flow.error.report("Unknown Random method: " + methodName, peek().lineNumber);
            return null;
        }
    }

    private function parseSystemExpression():Expression {
        var methodNameToken:Token = advance();
        var methodName:String = methodNameToken.value;

        if (methodName == ".currentDate") {
            consume(TokenType.LPAREN, "Expected '(' after 'Date'");
            consume(TokenType.RPAREN, "Expected ')' after 'Date'");
            return new SystemExpression("currentDate");
        } else if (methodName == ".exit") {
            consume(TokenType.LPAREN, "Expected '(' after 'exit'");
            consume(TokenType.RPAREN, "Expected ')' after 'exit'");
            return new SystemExpression("exit");
        } else if (methodName == ".println") {
            consume(TokenType.LPAREN, "Expected '(' after 'println'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new SystemExpression("println", [expression]);
        } else if (methodName == ".sleep") {
            consume(TokenType.LPAREN, "Expected '(' after 'sleep'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new SystemExpression("sleep", [expression]);
        } else if (methodName == ".command") {
            consume(TokenType.LPAREN, "Expected '(' after 'command'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new SystemExpression("command", [expression]);
        } else if (methodName == ".systemName") {
            consume(TokenType.LPAREN, "Expected '(' after 'systemName'");
            consume(TokenType.RPAREN, "Expected ')' after 'systemName'");
            return new SystemExpression("systemName");
        } else if (methodName == ".openUrl") {
            consume(TokenType.LPAREN, "Expected '(' after 'openUrl'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new SystemExpression("openUrl", [expression]);
        } else {
            Flow.error.report("Unknown System method: " + methodName, peek().lineNumber);
            return null;
        }
    }

    private function parseFileExpression():Expression {
        var methodNameToken:Token = advance();
        var methodName:String = methodNameToken.value;

        if (methodName == ".readFile") {
            consume(TokenType.LPAREN, "Expected '(' after 'readFile'");
            var filePath:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after file path expression");
            return new FileExpression("readFile", [filePath]);
        } else if (methodName == ".writeFile") {
            consume(TokenType.LPAREN, "Expected '(' after 'writeFile'");
            var filePath:Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after file path expression");
            var content:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after content expression");
            return new FileExpression("writeFile", [filePath, content]);
        } else if (methodName == ".exists") {
            consume(TokenType.LPAREN, "Expected '(' after 'exists'");
            var filePath:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after file path expression");
            return new FileExpression("exists", [filePath]);
        } else {
            Flow.error.report("Unknown File method: " + methodName, peek().lineNumber);
            return null;
        }
    }

    private function parseJsonExpression():Expression {
        var methodNameToken:Token = advance();
        var methodName:String = methodNameToken.value;

        if (methodName == ".parse") {
            consume(TokenType.LPAREN, "Expected '(' after 'parse'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new JsonExpression("parse", [expression]);
        } else if (methodName == ".stringify") {
            consume(TokenType.LPAREN, "Expected '(' after 'stringify'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new JsonExpression("stringify", [expression]);
        } else if (methodName == ".isValid") {
            consume(TokenType.LPAREN, "Expected '(' after 'isValid'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new JsonExpression("isValid", [expression]);
        } else {
            Flow.error.report("Unknown Json method: " + methodName, peek().lineNumber);
            return null;
        }
    }

    private function parseMathExpression():Expression {
        var methodNameToken:Token = advance();
        var methodName:String = methodNameToken.value;

        var methods = [
            { name: ".getPI", args: 0 },
            { name: ".abs", args: 1 },
            { name: ".max", args: 2 },
            { name: ".min", args: 2 },
            { name: ".pow", args: 2 },
            { name: ".sqrt", args: 1 },
            { name: ".sin", args: 1 },
            { name: ".cos", args: 1 },
            { name: ".tan", args: 1 },
            { name: ".asin", args: 1 },
            { name: ".acos", args: 1 },
            { name: ".atan", args: 1 }
        ];

        var methodConfig = null;
        for (method in methods) {
            if (method.name == methodName) {
                methodConfig = method;
                break;
            }
        }
    
        if (methodConfig == null) {
            Flow.error.report("Unknown Math method: " + methodName, peek().lineNumber);
            return null;
        }
    
        consume(TokenType.LPAREN, "Expected '(' after '" + methodName + "'");
    
        var arguments:Array<Expression> = [];
    
        for (i in 0...methodConfig.args) {
            if (i > 0) {
                consume(TokenType.COMMA, "Expected ',' between arguments");
            }
            arguments.push(parseExpression());
        }
    
        consume(TokenType.RPAREN, "Expected ')' after arguments");
    
        return new MathExpression(methodName.substr(1), arguments);
    }

    private function parseCallExpression():Expression {
        var nameToken:Token = previous();
        var name:String = nameToken.value;
        var arguments:Array<Expression> = [];

        if (name == "chr") {
            consume(TokenType.LPAREN, "Expected '(' after 'chr'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new ChrFunctionCall(argument);
        } else if (name == "fill") {
            consume(TokenType.LPAREN, "Expected '(' after 'fill'");
            var size: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after size argument in 'fill'");
            var value: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new FillFunctionCall(size, value);
        } else if (name == "charAt") {
            consume(TokenType.LPAREN, "Expected '(' after 'charAt'");
            var stringExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after string argument in 'charAt'");
            var indexExpr: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new CharAtFunctionCall(stringExpr, indexExpr);
        } else if (name == "charCodeAt") {
            consume(TokenType.LPAREN, "Expected '(' after 'charCodeAt'");
            var stringExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after string argument in 'charCodeAt'");
            var indexExpr: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new CharCodeAtFunctionCall(stringExpr, indexExpr);
        } else if (name == "push") {
            consume(TokenType.LPAREN, "Expected '(' after 'push'");
            var array: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after array argument in 'push'");
            var value: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments in 'push'");
            return new PushFunctionCall(array, value);
        } else if (name == "pop") {
            consume(TokenType.LPAREN, "Expected '(' after 'pop'");
            var array: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after array argument in 'pop'");
            var variableToken: Token = consume(TokenType.IDENTIFIER, "Expected variable name after ','");
            consume(TokenType.RPAREN, "Expected ')' after arguments in 'pop'");
            var variable: String = variableToken.value;
            return new PopFunctionCall(array, variable);
        } else if (name == "str") {
            consume(TokenType.LPAREN, "Expected '(' after 'str'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new StrFunctionCall(argument);
        } else if (name == "substring") {
            consume(TokenType.LPAREN, "Expected '(' after 'substring'");
            var stringExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after string argument in 'substring'");
            var startExpr: Expression = parseExpression();
            var endExpr: Expression = null;
            if (match([TokenType.COMMA])) {
                endExpr = parseExpression();
            }
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new SubstringFunctionCall(stringExpr, startExpr, endExpr);
        } else if (name == "toUpperCase") {
            consume(TokenType.LPAREN, "Expected '(' after 'toUpperCase'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new ToUpperCaseFunctionCall(argument);
        } else if (name == "toLowerCase") {
            consume(TokenType.LPAREN, "Expected '(' after 'toLowerCase'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new ToLowerCaseFunctionCall(argument);
        } else if (name == "join") {
            consume(TokenType.LPAREN, "Expected '(' after 'join'");
            var arrayExpr: Expression = parseExpression();
            var delimiterExpr: Expression = null;
            if (match([TokenType.COMMA])) {
                delimiterExpr = parseExpression();
            }
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new JoinFunctionCall(arrayExpr, delimiterExpr);
        } else if (name == "split") {
            consume(TokenType.LPAREN, "Expected '(' after 'split'");
            var stringExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after string argument in 'split'");
            var delimiterExpr: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new SplitFunctionCall(stringExpr, delimiterExpr);
        } else if (name == "parseNumber") {
            consume(TokenType.LPAREN, "Expected '(' after 'parseNumber'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new ParseNumberFunctionCall(argument);
        } else if (name == "replace") {
            consume(TokenType.LPAREN, "Expected '(' after 'replace'");
            var stringExpr:Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after string argument in 'replace'");
            var targetExpr:Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after target argument in 'replace'");
            var replacementExpr:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new ReplaceFunctionCall(stringExpr, targetExpr, replacementExpr);
        } else if (name == "trim") {
            consume(TokenType.LPAREN, "Expected '(' after 'trim'");
            var argument:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new TrimFunctionCall(argument);
        } else if (name == "concat") {
            consume(TokenType.LPAREN, "Expected '(' after 'concat'");
            var firstExpr:Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after first string argument in 'concat'");
            var secondExpr:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new ConcatFunctionCall(firstExpr, secondExpr);
        } else if (name == "indexOf") {
            consume(TokenType.LPAREN, "Expected '(' after 'indexOf'");
            var stringExpr:Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after string argument in 'indexOf'");
            var searchExpr:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new IndexOfFunctionCall(stringExpr, searchExpr);
        } else if (name == "toString") {
            consume(TokenType.LPAREN, "Expected '(' after 'toString'");
            var argument:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new ToStringFunctionCall(argument);
        } else if (name == "startsWith") {
            consume(TokenType.LPAREN, "Expected '(' after 'startsWith'");
            var stringOrArrayExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after first argument in 'startsWith'");
            var searchExpr: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new StartsWithFunctionCall(stringOrArrayExpr, searchExpr);
        } else if (name == "endsWith") {
            consume(TokenType.LPAREN, "Expected '(' after 'endsWith'");
            var stringOrArrayExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after first argument in 'endsWith'");
            var searchExpr: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new EndsWithFunctionCall(stringOrArrayExpr, searchExpr);
        } else if (name == "slice") {
            consume(TokenType.LPAREN, "Expected '(' after 'slice'");
            var stringOrArrayExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after first argument in 'slice'");
            var startExpr: Expression = parseExpression();
            var endExpr: Expression = null;
            if (match([TokenType.COMMA])) {
                endExpr = parseExpression();
            }
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new SliceFunctionCall(stringOrArrayExpr, startExpr, endExpr);
        } else if (name == "set") {
            consume(TokenType.LPAREN, "Expected '(' after 'set'");
            var targetExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after target expression in 'set'");
            var keyExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after key expression in 'set'");
            var valueExpr: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after value expression in 'set'");
            return new SetFunctionCall(targetExpr, keyExpr, valueExpr);
        } else if (name == "get") {
            consume(TokenType.LPAREN, "Expected '(' after 'get'");
            var targetExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after target expression in 'get'");
            var keyExpr: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after key expression in 'get'");
            return new GetFunctionCall(targetExpr, keyExpr);
        } else if (name == "sort") {
            consume(TokenType.LPAREN, "Expected '(' after 'sort'");
            var arrayExpr: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after array argument in 'sort'");
            return new SortFunctionCall(arrayExpr);
        }

        var isMethodCall: Bool = name.indexOf(".") > -1;
        if (isMethodCall) {
            var parts: Array<String> = name.split(".");
            var objectName: String = parts.shift();
            var methodName: String = parts.join(".");

            consume(TokenType.LPAREN, "Expected '(' after method name");
    
            while (!check(TokenType.RPAREN)) {
                arguments.push(parseExpression());
                if (match([TokenType.COMMA])) {
                    // Consume comma
                }
            }

            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new MethodCallExpression(objectName, methodName, arguments);
        } else {
            consume(TokenType.LPAREN, "Expected '(' after function name");

            while (!check(TokenType.RPAREN)) {
                arguments.push(parseExpression());
                if (match([TokenType.COMMA])) {
                    // Consume comma
                }
            }

            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new CallExpression(name, arguments);
        }
    }

    private function parsePropertyAccess():Expression {
        var obj:Expression = new VariableExpression(previous().value);
        while (match([TokenType.DOT, TokenType.LBRACKET])) {
            if (peek().type == TokenType.DOT) {
                var property:Token = consume(TokenType.IDENTIFIER, "Expected property name");
                if (property.value == "length") {
                    obj = new PropertyAccessExpression(obj, "length");
                } else {
                    obj = new PropertyAccessExpression(obj, property.value);
                }
            } else {
                consume(TokenType.LBRACKET, "Expected '[' after array name");
                var index:Expression = parseExpression();
                consume(TokenType.RBRACKET, "Expected ']' after array index");
                obj = new ArrayAccessExpression(obj, index);
            }
        }
        return obj;
    }

    private function parseArrayAccess():Expression {
        var expr:Expression = new VariableExpression(previous().value);
        consume(TokenType.LBRACKET, "Expected '[' after array name");
        var index:Expression = parseExpression();
        consume(TokenType.RBRACKET, "Expected ']' after array index");
        return new ArrayAccessExpression(expr, index);
    }

    private function advance():Token {
        currentTokenIndex++;
        return previous();
    }

    private function isAtEnd():Bool {
        return currentTokenIndex >= tokens.length;
    }

    private function peekNext():Token {
        return tokens[currentTokenIndex + 1];
    }

    private function previous():Token {
        return tokens[currentTokenIndex - 1];
    }

    private function peek():Token {
        return tokens[currentTokenIndex];
    }

    private function match(tokenTypes:Array<TokenType>):Bool {
        for (tokenType in tokenTypes) {
            if (check(tokenType)) {
                advance();
                return true;
            }
        }
        return false;
    }

    private function check(tokenType:TokenType):Bool {
        if (isAtEnd()) return false;
        return peek().type == tokenType;
    }

    private function consume(tokenType:TokenType, message:String):Token {
        if (!check(tokenType)) {
            Flow.error.report(message, peek().lineNumber);
        }
        return advance();
    }
}
