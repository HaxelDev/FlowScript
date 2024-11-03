package flow;

import flow.Lexer;
import flow.Program;
import logs.*;

using StringTools;

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
        } else if (firstTokenType == TokenType.HTTP) {
            return parseHttpStatement();
        } else if (firstTokenType == TokenType.DATE) {
            return parseDateStatement();
        } else if (firstTokenType == TokenType.IDENTIFIER) {
            if (peekNext().type == TokenType.LBRACKET) {
                return parseArrayAssignment();
            } else {
                return parseLetStatement();
            }
        } else if (firstTokenType == TokenType.PLUS_PLUS || firstTokenType == TokenType.MINUS_MINUS) {
            var opera: String = advance().value;
            var nameToken: Token = consume(TokenType.IDENTIFIER, "Expected variable name after '" + opera + "'");
            var name: String = nameToken.value;
            return new LetStatement(name, opera, null, true);
        } else {
            Flow.error.report("Unexpected token: " + peek().value, peek().lineNumber);
            return null;
        }
    }

    private function parseLetStatement(): LetStatement {
        var nameToken: Token = consume(TokenType.IDENTIFIER, "Expected variable name after 'let'");
        var name: String = nameToken.value;

        while (match([TokenType.DOT])) {
            var propertyToken: Token = consume(TokenType.IDENTIFIER, "Expected property name after '.'");
            name += "." + propertyToken.value;
        }

        var opera: String = "";

        if (match([TokenType.EQUAL, TokenType.PLUS_EQUAL, TokenType.MINUS_EQUAL, TokenType.PLUS_PLUS, TokenType.MINUS_MINUS])) {
            opera = previous().value;
        } else {
            Flow.error.report("Expected '=', '+=', '-=', '++', or '--' after variable name or property access", peek().lineNumber);
            return null;
        }

        var initializer: Expression = (opera == "++" || opera == "--") ? null : parseExpression();
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

        var iterableExpression:Expression = parseExpression();

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
        } else if (name == "remove") {
            return parseRemoveStatement();
        } else if (name == "set") {
            return parseSetStatement();
        } else if (name == "get") {
            return parseGetStatement();
        } else if (name == "exists") {
            return parseExistsStatement();
        } else if (name == "sort") {
            return parseSortStatement();
        } else if (name == "splice") {
            return parseSpliceStatement();
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
        var firstToken:Token = consume(TokenType.STRING, "Expected library or script identifier");
        if (firstToken.value.startsWith("lib::")) {
            var parts = firstToken.value.split("::");
            var libraryName = parts[1].trim();
            var version:String = null;
            if (match([TokenType.COMMA])) {
                var versionToken:Token = consume(TokenType.STRING, "Expected version after comma");
                if (versionToken.value.startsWith("v::")) {
                    version = versionToken.value.split("::")[1].trim();
                }
            }
            return new ImportStatement(libraryName, version, true);
        } else {
            return new ImportStatement(firstToken.value, null, false);
        }
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

    private function parseEnumStatement(): Statement {
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

    private function parseRemoveStatement(): Statement {
        consume(TokenType.LPAREN, "Expected '(' after 'remove'");
        var array: Expression = parseExpression();
        consume(TokenType.COMMA, "Expected ',' after array argument in 'remove'");
        var element: Expression = parseExpression();
        consume(TokenType.COMMA, "Expected ',' after element argument in 'remove'");
        var variableToken: Token = consume(TokenType.IDENTIFIER, "Expected variable name after ','");
        consume(TokenType.RPAREN, "Expected ')' after arguments in 'remove'");
        var variable: String = variableToken.value;
        return new RemoveStatement(array, element, variable);
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

    private function parseExistsStatement(): Statement {
        consume(TokenType.LPAREN, "Expected '(' after 'exists'");
        var targetExpr: Expression = parseExpression();
        consume(TokenType.COMMA, "Expected ',' after target expression in 'exists'");
        var keyExpr: Expression = parseExpression();
        consume(TokenType.RPAREN, "Expected ')' after key expression in 'exists'");
        return new ExistsStatement(targetExpr, keyExpr);
    }

    private function parseSortStatement(): Statement {
        consume(TokenType.LPAREN, "Expected '(' after 'sort'");
        var arrayExpr: Expression = parseExpression();
        consume(TokenType.RPAREN, "Expected ')' after array argument in 'sort'");
        return new SortStatement(arrayExpr);
    }

    private function parseSpliceStatement(): Statement {
        consume(TokenType.LPAREN, "Expected '(' after 'splice'");
        var arrayExpr: Expression = parseExpression();
        consume(TokenType.COMMA, "Expected ',' after array argument in 'splice'");
        var startIndexExpr: Expression = parseExpression();
        consume(TokenType.COMMA, "Expected ',' after start index in 'splice'");
        var deleteCountExpr: Expression = parseExpression();
        consume(TokenType.RPAREN, "Expected ')' after arguments in 'splice'");
        return new SpliceStatement(arrayExpr, startIndexExpr, deleteCountExpr);
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

        switch (methodName) {
            case ".nextInt":
                var lparenToken:Token = advance();
                if (lparenToken.type != TokenType.LPAREN) {
                    Flow.error.report("Expected '(' after method name", peek().lineNumber);
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
            case ".choice":
                var lparenToken:Token = advance();
                if (lparenToken.type != TokenType.LPAREN) {
                    Flow.error.report("Expected '(' after method name", peek().lineNumber);
                    return null;
                }
                var listExpr:Expression = parseExpression();
                var rparenToken:Token = advance();
                if (rparenToken.type != TokenType.RPAREN) {
                    Flow.error.report("Expected ')' after list", peek().lineNumber);
                    return null;
                }
                return new RandomStatement(methodName, [listExpr]);
            case ".weightedChoice":
                var lparenToken:Token = advance();
                if (lparenToken.type != TokenType.LPAREN) {
                    Flow.error.report("Expected '(' after method name", peek().lineNumber);
                    return null;
                }
                var listExpr:Expression = parseExpression();
                var commaToken:Token = advance();
                if (commaToken.type != TokenType.COMMA) {
                    Flow.error.report("Expected ',' after list", peek().lineNumber);
                    return null;
                }
                var weightsExpr:Expression = parseExpression();
                var rparenToken:Token = advance();
                if (rparenToken.type != TokenType.RPAREN) {
                    Flow.error.report("Expected ')' after weights", peek().lineNumber);
                    return null;
                }
                return new RandomStatement(methodName, [listExpr, weightsExpr]);
            case ".shuffle":
                var lparenToken:Token = advance();
                if (lparenToken.type != TokenType.LPAREN) {
                    Flow.error.report("Expected '(' after method name", peek().lineNumber);
                    return null;
                }
                var listExpr:Expression = parseExpression();
                var rparenToken:Token = advance();
                if (rparenToken.type != TokenType.RPAREN) {
                    Flow.error.report("Expected ')' after list", peek().lineNumber);
                    return null;
                }
                return new RandomStatement(methodName, [listExpr]);
            case ".sample":
                var lparenToken:Token = advance();
                if (lparenToken.type != TokenType.LPAREN) {
                    Flow.error.report("Expected '(' after method name", peek().lineNumber);
                    return null;
                }
                var listExpr:Expression = parseExpression();
                var commaToken:Token = advance();
                if (commaToken.type != TokenType.COMMA) {
                    Flow.error.report("Expected ',' after list", peek().lineNumber);
                    return null;
                }
                var nExpr:Expression = parseExpression();
                var rparenToken:Token = advance();
                if (rparenToken.type != TokenType.RPAREN) {
                    Flow.error.report("Expected ')' after sample size", peek().lineNumber);
                    return null;
                }
                return new RandomStatement(methodName, [listExpr, nExpr]);
            case ".gaussian":
                var lparenToken:Token = advance();
                if (lparenToken.type != TokenType.LPAREN) {
                    Flow.error.report("Expected '(' after method name", peek().lineNumber);
                    return null;
                }
                var meanExpr:Expression = parseExpression();
                var commaToken:Token = advance();
                if (commaToken.type != TokenType.COMMA) {
                    Flow.error.report("Expected ',' after mean", peek().lineNumber);
                    return null;
                }
                var stddevExpr:Expression = parseExpression();
                var rparenToken:Token = advance();
                if (rparenToken.type != TokenType.RPAREN) {
                    Flow.error.report("Expected ')' after standard deviation", peek().lineNumber);
                    return null;
                }
                return new RandomStatement(methodName, [meanExpr, stddevExpr]);
            default:
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
        } else if (methodName == ".args") {
            consume(TokenType.LPAREN, "Expected '(' after 'exit'");
            consume(TokenType.RPAREN, "Expected ')' after 'exit'");
            return new SystemStatement("args");
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

        switch (methodName) {
            case ".readFile":
                consume(TokenType.LPAREN, "Expected '(' after 'readFile'");
                var filePath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after file path expression");
                return new FileStatement("readFile", [filePath]);
            case ".writeFile":
                consume(TokenType.LPAREN, "Expected '(' after 'writeFile'");
                var filePath:Expression = parseExpression();
                consume(TokenType.COMMA, "Expected ',' after file path expression");
                var content:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after content expression");
                return new FileStatement("writeFile", [filePath, content]);
            case ".exists":
                consume(TokenType.LPAREN, "Expected '(' after 'exists'");
                var filePath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after file path expression");
                return new FileStatement("exists", [filePath]);
            case ".appendToFile":
                consume(TokenType.LPAREN, "Expected '(' after 'appendToFile'");
                var appendFilePath:Expression = parseExpression();
                consume(TokenType.COMMA, "Expected ',' after file path expression");
                var appendContent:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after content expression");
                return new FileStatement("appendToFile", [appendFilePath, appendContent]);
            case ".deleteFile":
                consume(TokenType.LPAREN, "Expected '(' after 'deleteFile'");
                var deleteFilePath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after file path expression");
                return new FileStatement("deleteFile", [deleteFilePath]);
            case ".copyFile":
                consume(TokenType.LPAREN, "Expected '(' after 'copyFile'");
                var sourcePath:Expression = parseExpression();
                consume(TokenType.COMMA, "Expected ',' after source path expression");
                var destinationPath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after destination path expression");
                return new FileStatement("copyFile", [sourcePath, destinationPath]);
            case ".renameFile":
                consume(TokenType.LPAREN, "Expected '(' after 'renameFile'");
                var oldPath:Expression = parseExpression();
                consume(TokenType.COMMA, "Expected ',' after old path expression");
                var newPath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after new path expression");
                return new FileStatement("renameFile", [oldPath, newPath]);
            case ".readLines":
                consume(TokenType.LPAREN, "Expected '(' after 'readLines'");
                var linesFilePath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after file path expression");
                return new FileStatement("readLines", [linesFilePath]);
            case ".getFileSize":
                consume(TokenType.LPAREN, "Expected '(' after 'getFileSize'");
                var fileSizePath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after file path expression");
                return new FileStatement("getFileSize", [fileSizePath]);
            case ".listFilesInDirectory":
                consume(TokenType.LPAREN, "Expected '(' after 'listFilesInDirectory'");
                var directoryPath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after directory path expression");
                return new FileStatement("listFilesInDirectory", [directoryPath]);
            case ".createDirectory":
                consume(TokenType.LPAREN, "Expected '(' after 'createDirectory'");
                var directoryPath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after directory path expression");
                return new FileStatement("createDirectory", [directoryPath]);
            case ".getFileExtension":
                consume(TokenType.LPAREN, "Expected '(' after 'getFileExtension'");
                var filePath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after file path expression");
                return new FileStatement("getFileExtension", [filePath]);
            default:
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
            { name: ".atan", args: 1 },
            { name: ".floor", args: 1 },
            { name: ".round", args: 1 },
            { name: ".ceil", args: 1 },
            { name: ".trunc", args: 1 },
            { name: ".random", args: 0 }
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

    private function parseHttpStatement():Statement {
        var httpToken:Token = advance();
        if (httpToken.type != TokenType.HTTP) {
            Flow.error.report("Expected 'HTTP' keyword", peek().lineNumber);
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

        if (methodName == ".get") {
            consume(TokenType.LPAREN, "Expected '(' after 'get'");
            var urlExpression:Expression = parseExpression();
            var headers:Map<String, String> = new Map<String, String>();
            if (match([TokenType.COMMA])) {
                consume(TokenType.LBRACE, "Expected '{' for headers");
                while (!check(TokenType.RBRACE)) {
                    var headerKey:Token = advance();
                    consume(TokenType.COLON, "Expected ':' after header key");
                    var headerValue:Expression = parseExpression();
                    headers.set(headerKey.value, headerValue.evaluate());
                    if (!match([TokenType.COMMA])) {
                        break;
                    }
                }
                consume(TokenType.RBRACE, "Expected '}' after headers");
            }
            consume(TokenType.RPAREN, "Expected ')' after expression(s)");
            return new HttpStatement("get", urlExpression, null, headers);
        } else if (methodName == ".post") {
            consume(TokenType.LPAREN, "Expected '(' after 'post'");
            var urlExpression:Expression = parseExpression();
            var dataExpression:Expression = null;
            if (match([TokenType.COMMA])) {
                dataExpression = parseExpression();
            }
            var headers:Map<String, String> = new Map<String, String>();
            if (match([TokenType.COMMA])) {
                consume(TokenType.LBRACE, "Expected '{' for headers");
                while (!check(TokenType.RBRACE)) {
                    var headerKey:Token = advance();
                    consume(TokenType.COLON, "Expected ':' after header key");
                    var headerValue:Expression = parseExpression();
                    headers.set(headerKey.value, headerValue.evaluate());
                    if (!match([TokenType.COMMA])) {
                        break;
                    }
                }
                consume(TokenType.RBRACE, "Expected '}' after headers");
            }
            consume(TokenType.RPAREN, "Expected ')' after expression(s)");
            return new HttpStatement("post", urlExpression, dataExpression, headers);
        } else {
            Flow.error.report("Unknown HTTP method: " + methodName, peek().lineNumber);
            return null;
        }
    }

    private function parseDateStatement():Statement {
        var dateToken:Token = advance();
        if (dateToken.type != TokenType.DATE) {
            Flow.error.report("Expected 'Date' keyword", peek().lineNumber);
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

        if (methodName == ".getCurrentDateTime") {
            consume(TokenType.RPAREN, "Expected ')' after 'getCurrentDateTime'");
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new DateStatement("getCurrentDateTime");
        } else if (methodName == ".getCurrentDate") {
            consume(TokenType.RPAREN, "Expected ')' after 'getCurrentDate'");
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new DateStatement("getCurrentDate");
        } else if (methodName == ".getCurrentTime") {
            consume(TokenType.RPAREN, "Expected ')' after 'getCurrentTime'");
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new DateStatement("getCurrentTime");
        } else if (methodName == ".formatDate") {
            consume(TokenType.LPAREN, "Expected '(' after 'formatDate'");
            var dateExpression:Expression = parseExpression();
            var formatExpression:Expression = null;
            if (match([TokenType.COMMA])) {
                formatExpression = parseExpression();
            }
            consume(TokenType.RPAREN, "Expected ')' after expression");
            if (formatExpression != null) {
                return new DateStatement("formatDate", [dateExpression, formatExpression]);
            } else {
                return new DateStatement("formatDate", [dateExpression]);
            }
        } else if (methodName == ".formatTime") {
            consume(TokenType.LPAREN, "Expected '(' after 'formatTime'");
            var timeExpression:Expression = parseExpression();
            var formatExpression:Expression = null;
            if (match([TokenType.COMMA])) {
                formatExpression = parseExpression();
            }
            consume(TokenType.RPAREN, "Expected ')' after expression");
            if (formatExpression != null) {
                return new DateStatement("formatTime", [timeExpression, formatExpression]);
            } else {
                return new DateStatement("formatTime", [timeExpression]);
            }
        } else if (methodName == ".diffInSeconds") {
            consume(TokenType.LPAREN, "Expected '(' after 'diffInSeconds'");
            var expr1:Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' between dates in 'diffInSeconds'");
            var expr2:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after second date");
            return new DateStatement("diffInSeconds", [expr1, expr2]);
        } else {
            Flow.error.report("Unknown Date method: " + methodName, peek().lineNumber);
            return null;
        }
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

    private function parseExpression():Expression {
        var firstTokenType:TokenType = peek().type;
        if (firstTokenType == TokenType.KEYWORD) {
            var keyword:String = advance().value;
            if (keyword == "func") {
                return parseFunctionLiteral();
            } else if (keyword == "lambda") {
                return parseLambdaExpression();
            }
        } else if (firstTokenType == TokenType.LBRACKET) {
            return parseArrayLiteral();
        } else if (firstTokenType == TokenType.LBRACE) {
            return parseObjectLiteral();
        }
        return parseTernaryExpression();
    }

    private function parseLambdaExpression(): Expression {
        var parameters: Array<Parameter> = [];
        if (match([TokenType.LPAREN])) {
            parameters = parseParameterList();
            consume(TokenType.RPAREN, "Expected ')' after parameters");
        }
        consume(TokenType.ARROW, "Expected '=>' after lambda parameters");
        var singleExpression: Expression = parseExpression();
        var body: BlockStatement = new BlockStatement([new ReturnStatement(singleExpression)]);
        return new FunctionLiteralExpression(parameters, body);
    }

    private function parseParameterList(): Array<Parameter> {
        var parameters: Array<Parameter> = [];
        do {
            parameters.push(parseParameter());
        } while (match([TokenType.COMMA]));
        return parameters;
    }
    
    private function parseParameter(): Parameter {
        var name: String = consume(TokenType.IDENTIFIER, "Expected parameter name").value;
        var defaultValue: Expression = null;
        if (match([TokenType.EQUAL])) {
            defaultValue = parseExpression();
        }
        return new Parameter(name, defaultValue);
    }

    private function parseTernaryExpression():Expression {
        var expr = parseLogicalOr();
        if (match([TokenType.QUESTION])) {
            var trueBranch = parseExpression();
            consume(TokenType.COLON, "Expected ':' after '?'");
            var falseBranch = parseExpression();
            return new TernaryExpression(expr, trueBranch, falseBranch);
        }
        return expr;
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
        var expr = parseFactor();
        while (match([TokenType.PLUS, TokenType.MINUS])) {
            var opera = previous().value;
            var right = parseFactor();
            expr = new BinaryExpression(expr, opera, right);
        }
        return expr;
    }

    private function parseFactor(): Expression {
        var expr = parseUnary();
        while (match([TokenType.MULTIPLY, TokenType.DIVIDE, TokenType.MODULO])) {
            var opera = previous().value;
            var right = parseUnary();
            expr = new BinaryExpression(expr, opera, right);
        }
        return expr;
    }

    private function parseUnary(): Expression {
        if (match([TokenType.NOT])) {
            var operand = parseUnary();
            return new UnaryExpression("not", operand, true);
        } else if (match([TokenType.MINUS])) {
            var operand = parseUnary();
            return new UnaryExpression("-", operand, true);
        } else if (match([TokenType.PLUS_PLUS, TokenType.MINUS_MINUS])) {
            var opera = previous().value;
            var operand = parseUnary();
            return new UnaryExpression(opera, operand, true);
        }
        return parsePrimary();
    }

    private function parsePrimary(): Expression {
        if (match([TokenType.NUMBER])) {
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
        } else if (match([TokenType.HTTP])) {
            consume(TokenType.LPAREN, "Expected '('");
            consume(TokenType.RPAREN, "Expected ')'");
            return parseHttpExpression();
        } else if (match([TokenType.DATE])) {
            consume(TokenType.LPAREN, "Expected '('");
            consume(TokenType.RPAREN, "Expected ')'");
            return parseDateExpression();
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
        } else if (match([TokenType.NULL])) {
            return new LiteralExpression(null);
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
        var value: String = previous().value;
        var parts: Array<Expression> = [];
        var currentPart: String = "";
        var i: Int = 0;

        while (i < value.length) {
            var char: String = value.charAt(i);

            if (char == '{') {

                if (currentPart.length > 0) {
                    parts.push(new LiteralExpression(currentPart));
                    currentPart = "";
                }

                i++;
                var expression: String = "";

                while (i < value.length && value.charAt(i) != '}') {
                    expression += value.charAt(i);
                    i++;
                }

                if (i < value.length && value.charAt(i) == '}') {
                    if (expression.length == 0) {
                        parts.push(new LiteralExpression("{}"));
                    } else {
                        parts.push(parseEmbeddedExpression(expression));
                    }
                } else {
                    Flow.error.report("Unmatched '{' in string.", peek().lineNumber);
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

    private function parseEmbeddedExpression(expressionString: String): Expression {
        var innerParser = new ExpressionParser(expressionString);
        return innerParser.parseExpression();
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

        switch (methodName) {
            case ".nextInt":
                var lparenToken:Token = advance();
                if (lparenToken.type != TokenType.LPAREN) {
                    Flow.error.report("Expected '(' after method name", peek().lineNumber);
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
            case ".choice":
                var lparenToken:Token = advance();
                if (lparenToken.type != TokenType.LPAREN) {
                    Flow.error.report("Expected '(' after method name", peek().lineNumber);
                    return null;
                }
                var listExpr:Expression = parseExpression();
                var rparenToken:Token = advance();
                if (rparenToken.type != TokenType.RPAREN) {
                    Flow.error.report("Expected ')' after list", peek().lineNumber);
                    return null;
                }
                return new RandomExpression(methodName, [listExpr]);
            case ".weightedChoice":
                var lparenToken:Token = advance();
                if (lparenToken.type != TokenType.LPAREN) {
                    Flow.error.report("Expected '(' after method name", peek().lineNumber);
                    return null;
                }
                var listExpr:Expression = parseExpression();
                var commaToken:Token = advance();
                if (commaToken.type != TokenType.COMMA) {
                    Flow.error.report("Expected ',' after list", peek().lineNumber);
                    return null;
                }
                var weightsExpr:Expression = parseExpression();
                var rparenToken:Token = advance();
                if (rparenToken.type != TokenType.RPAREN) {
                    Flow.error.report("Expected ')' after weights", peek().lineNumber);
                    return null;
                }
                return new RandomExpression(methodName, [listExpr, weightsExpr]);
            case ".shuffle":
                var lparenToken:Token = advance();
                if (lparenToken.type != TokenType.LPAREN) {
                    Flow.error.report("Expected '(' after method name", peek().lineNumber);
                    return null;
                }
                var listExpr:Expression = parseExpression();
                var rparenToken:Token = advance();
                if (rparenToken.type != TokenType.RPAREN) {
                    Flow.error.report("Expected ')' after list", peek().lineNumber);
                    return null;
                }
                return new RandomExpression(methodName, [listExpr]);
            case ".sample":
                var lparenToken:Token = advance();
                if (lparenToken.type != TokenType.LPAREN) {
                    Flow.error.report("Expected '(' after method name", peek().lineNumber);
                    return null;
                }
                var listExpr:Expression = parseExpression();
                var commaToken:Token = advance();
                if (commaToken.type != TokenType.COMMA) {
                    Flow.error.report("Expected ',' after list", peek().lineNumber);
                    return null;
                }
                var nExpr:Expression = parseExpression();
                var rparenToken:Token = advance();
                if (rparenToken.type != TokenType.RPAREN) {
                    Flow.error.report("Expected ')' after sample size", peek().lineNumber);
                    return null;
                }
                return new RandomExpression(methodName, [listExpr, nExpr]);
            case ".gaussian":
                var lparenToken:Token = advance();
                if (lparenToken.type != TokenType.LPAREN) {
                    Flow.error.report("Expected '(' after method name", peek().lineNumber);
                    return null;
                }
                var meanExpr:Expression = parseExpression();
                var commaToken:Token = advance();
                if (commaToken.type != TokenType.COMMA) {
                    Flow.error.report("Expected ',' after mean", peek().lineNumber);
                    return null;
                }
                var stddevExpr:Expression = parseExpression();
                var rparenToken:Token = advance();
                if (rparenToken.type != TokenType.RPAREN) {
                    Flow.error.report("Expected ')' after standard deviation", peek().lineNumber);
                    return null;
                }
                return new RandomExpression(methodName, [meanExpr, stddevExpr]);
            default:
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
        } else if (methodName == ".args") {
            consume(TokenType.LPAREN, "Expected '(' after 'exit'");
            consume(TokenType.RPAREN, "Expected ')' after 'exit'");
            return new SystemExpression("args");
        } else {
            Flow.error.report("Unknown System method: " + methodName, peek().lineNumber);
            return null;
        }
    }

    private function parseFileExpression():Expression {
        var methodNameToken:Token = advance();
        var methodName:String = methodNameToken.value;
    
        switch (methodName) {
            case ".readFile":
                consume(TokenType.LPAREN, "Expected '(' after 'readFile'");
                var filePath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after file path expression");
                return new FileExpression("readFile", [filePath]);
            case ".writeFile":
                consume(TokenType.LPAREN, "Expected '(' after 'writeFile'");
                var filePath:Expression = parseExpression();
                consume(TokenType.COMMA, "Expected ',' after file path expression");
                var content:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after content expression");
                return new FileExpression("writeFile", [filePath, content]);
            case ".exists":
                consume(TokenType.LPAREN, "Expected '(' after 'exists'");
                var filePath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after file path expression");
                return new FileExpression("exists", [filePath]);
            case ".appendToFile":
                consume(TokenType.LPAREN, "Expected '(' after 'appendToFile'");
                var appendFilePath:Expression = parseExpression();
                consume(TokenType.COMMA, "Expected ',' after file path expression");
                var appendContent:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after content expression");
                return new FileExpression("appendToFile", [appendFilePath, appendContent]);
            case ".deleteFile":
                consume(TokenType.LPAREN, "Expected '(' after 'deleteFile'");
                var deleteFilePath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after file path expression");
                return new FileExpression("deleteFile", [deleteFilePath]);
            case ".copyFile":
                consume(TokenType.LPAREN, "Expected '(' after 'copyFile'");
                var sourcePath:Expression = parseExpression();
                consume(TokenType.COMMA, "Expected ',' after source path expression");
                var destinationPath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after destination path expression");
                return new FileExpression("copyFile", [sourcePath, destinationPath]);
            case ".renameFile":
                consume(TokenType.LPAREN, "Expected '(' after 'renameFile'");
                var oldPath:Expression = parseExpression();
                consume(TokenType.COMMA, "Expected ',' after old path expression");
                var newPath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after new path expression");
                return new FileExpression("renameFile", [oldPath, newPath]);
            case ".readLines":
                consume(TokenType.LPAREN, "Expected '(' after 'readLines'");
                var linesFilePath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after file path expression");
                return new FileExpression("readLines", [linesFilePath]);
            case ".getFileSize":
                consume(TokenType.LPAREN, "Expected '(' after 'getFileSize'");
                var fileSizePath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after file path expression");
                return new FileExpression("getFileSize", [fileSizePath]);
            case ".listFilesInDirectory":
                consume(TokenType.LPAREN, "Expected '(' after 'listFilesInDirectory'");
                var directoryPath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after directory path expression");
                return new FileExpression("listFilesInDirectory", [directoryPath]);
            case ".createDirectory":
                consume(TokenType.LPAREN, "Expected '(' after 'createDirectory'");
                var directoryPath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after directory path expression");
                return new FileExpression("createDirectory", [directoryPath]);
            case ".getFileExtension":
                consume(TokenType.LPAREN, "Expected '(' after 'getFileExtension'");
                var filePath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after file path expression");
                return new FileExpression("getFileExtension", [filePath]);
            default:
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
            { name: ".atan", args: 1 },
            { name: ".floor", args: 1 },
            { name: ".round", args: 1 },
            { name: ".ceil", args: 1 },
            { name: ".trunc", args: 1 },
            { name: ".random", args: 0 }
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

    private function parseHttpExpression():Expression {
        var methodNameToken:Token = advance();
        var methodName:String = methodNameToken.value;

        if (methodName == ".get") {
            consume(TokenType.LPAREN, "Expected '(' after 'get'");
            var urlExpression:Expression = parseExpression();
            var headers:Map<String, String> = new Map<String, String>();
            if (match([TokenType.COMMA])) {
                consume(TokenType.LBRACE, "Expected '{' for headers");
                while (!check(TokenType.RBRACE)) {
                    var headerKey:Token = advance();
                    consume(TokenType.COLON, "Expected ':' after header key");
                    var headerValue:Expression = parseExpression();
                    headers.set(headerKey.value, headerValue.evaluate());
                    if (!match([TokenType.COMMA])) {
                        break;
                    }
                }
                consume(TokenType.RBRACE, "Expected '}' after headers");
            }
            consume(TokenType.RPAREN, "Expected ')' after expression(s)");
            return new HttpExpression("get", urlExpression, null, headers);
        } else if (methodName == ".post") {
            consume(TokenType.LPAREN, "Expected '(' after 'post'");
            var urlExpression:Expression = parseExpression();
            var dataExpression:Expression = null;
            if (match([TokenType.COMMA])) {
                dataExpression = parseExpression();
            }
            var headers:Map<String, String> = new Map<String, String>();
            if (match([TokenType.COMMA])) {
                consume(TokenType.LBRACE, "Expected '{' for headers");
                while (!check(TokenType.RBRACE)) {
                    var headerKey:Token = advance();
                    consume(TokenType.COLON, "Expected ':' after header key");
                    var headerValue:Expression = parseExpression();
                    headers.set(headerKey.value, headerValue.evaluate());
                    if (!match([TokenType.COMMA])) {
                        break;
                    }
                }
                consume(TokenType.RBRACE, "Expected '}' after headers");
            }
            consume(TokenType.RPAREN, "Expected ')' after expression(s)");
            return new HttpExpression("post", urlExpression, dataExpression, headers);
        } else {
            Flow.error.report("Unknown HTTP method: " + methodName, peek().lineNumber);
            return null;
        }
    }

    private function parseDateExpression():Expression {
        var methodNameToken:Token = advance();
        var methodName:String = methodNameToken.value;

        if (methodName == ".getCurrentDateTime") {
            consume(TokenType.LPAREN, "Expected '(' after 'getCurrentDateTime'");
            consume(TokenType.RPAREN, "Expected ')' after 'getCurrentDateTime'");
            return new DateExpression("getCurrentDateTime");
        } else if (methodName == ".getCurrentDate") {
            consume(TokenType.LPAREN, "Expected '(' after 'getCurrentDate'");
            consume(TokenType.RPAREN, "Expected ')' after 'getCurrentDate'");
            return new DateExpression("getCurrentDate");
        } else if (methodName == ".getCurrentTime") {
            consume(TokenType.LPAREN, "Expected '(' after 'getCurrentTime'");
            consume(TokenType.RPAREN, "Expected ')' after 'getCurrentTime'");
            return new DateExpression("getCurrentTime");
        } else if (methodName == ".formatDate") {
            consume(TokenType.LPAREN, "Expected '(' after 'formatDate'");
            var dateExpression:Expression = parseExpression();
            var formatExpression:Expression = null;
            if (match([TokenType.COMMA])) {
                formatExpression = parseExpression();
            }
            consume(TokenType.RPAREN, "Expected ')' after expression");
            if (formatExpression != null) {
                return new DateExpression("formatDate", [dateExpression, formatExpression]);
            } else {
                return new DateExpression("formatDate", [dateExpression]);
            }
        } else if (methodName == ".formatTime") {
            consume(TokenType.LPAREN, "Expected '(' after 'formatTime'");
            var timeExpression:Expression = parseExpression();
            var formatExpression:Expression = null;
            if (match([TokenType.COMMA])) {
                formatExpression = parseExpression();
            }
            consume(TokenType.RPAREN, "Expected ')' after expression");
            if (formatExpression != null) {
                return new DateExpression("formatTime", [timeExpression, formatExpression]);
            } else {
                return new DateExpression("formatTime", [timeExpression]);
            }
        } else if (methodName == ".fromString") {
            consume(TokenType.LPAREN, "Expected '(' after 'fromString'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new DateExpression("fromString", [expression]);
        } else if (methodName == ".diffInSeconds") {
            consume(TokenType.LPAREN, "Expected '(' after 'diffInSeconds'");
            var expr1:Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' between dates in 'diffInSeconds'");
            var expr2:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after second date");
            return new DateExpression("diffInSeconds", [expr1, expr2]);
        } else {
            Flow.error.report("Unknown Date method: " + methodName, peek().lineNumber);
            return null;
        }
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
        } else if (name == "remove") {
            consume(TokenType.LPAREN, "Expected '(' after 'remove'");
            var array: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after array argument in 'remove'");
            var element: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after element argument in 'remove'");
            var variableToken: Token = consume(TokenType.IDENTIFIER, "Expected variable name after ','");
            consume(TokenType.RPAREN, "Expected ')' after arguments in 'remove'");
            var variable: String = variableToken.value;
            return new RemoveFunctionCall(array, element, variable);            
        } else if (name == "str") {
            consume(TokenType.LPAREN, "Expected '(' after 'str'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new StrFunctionCall(argument);
        } else if (name == "int") {
            consume(TokenType.LPAREN, "Expected '(' after 'int'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new IntFunctionCall(argument);
        } else if (name == "float") {
            consume(TokenType.LPAREN, "Expected '(' after 'float'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new FloatFunctionCall(argument);
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
        } else if (name == "parseInt") {
            consume(TokenType.LPAREN, "Expected '(' after 'parseInt'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new IntFunctionCall(argument);
        } else if (name == "parseFloat") {
            consume(TokenType.LPAREN, "Expected '(' after 'parseFloat'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new FloatFunctionCall(argument);
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
        } else if (name == "exists") {
            consume(TokenType.LPAREN, "Expected '(' after 'exists'");
            var targetExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after target expression in 'exists'");
            var keyExpr: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after key expression in 'exists'");
            return new ExistsFunctionCall(targetExpr, keyExpr);
        } else if (name == "sort") {
            consume(TokenType.LPAREN, "Expected '(' after 'sort'");
            var arrayExpr: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after array argument in 'sort'");
            return new SortFunctionCall(arrayExpr);
        } else if (name == "capitalize") {
            consume(TokenType.LPAREN, "Expected '(' after 'capitalize'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new CapitalizeFunctionCall(argument);
        } else if (name == "reverse") {
            consume(TokenType.LPAREN, "Expected '(' after 'reverse'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new ReverseFunctionCall(argument);
        } else if (name == "isDigit") {
            consume(TokenType.LPAREN, "Expected '(' after 'isDigit'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new IsDigitFunctionCall(argument);
        } else if (name == "isNumeric") {
            consume(TokenType.LPAREN, "Expected '(' after 'isNumeric'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new IsNumericFunctionCall(argument);
        } else if (name == "center") {
            consume(TokenType.LPAREN, "Expected '(' after 'center'");
            var argument: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after argument");
            var width: Expression = parseExpression();
            var fillChar: Expression = null;
            if (match([TokenType.COMMA])) {
                fillChar = parseExpression();
            }
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new CenterFunctionCall(argument, width, fillChar);
        } else if (name == "count") {
            consume(TokenType.LPAREN, "Expected '(' after 'count'");
            var argument: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after first argument");
            var target: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new CountFunctionCall(argument, target);
        } else if (name == "calculate") {
            consume(TokenType.LPAREN, "Expected '(' after 'eval'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new CalculateFunctionCall(argument);
        } else if (name == "repeat") {
            consume(TokenType.LPAREN, "Expected '(' after 'repeat'");
            var stringArgument:Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after string argument");
            var countArgument:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new RepeatFunctionCall(stringArgument, countArgument);
        } else if (name == "range") {
            consume(TokenType.LPAREN, "Expected '(' after 'range'");
            var start: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after start argument");
            var end: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new RangeExpression(start, end);
        } else if (name == "padStart") {
            consume(TokenType.LPAREN, "Expected '(' after 'padStart'");
            var stringExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after string argument in 'padStart'");
            var lengthExpr: Expression = parseExpression();
            var charExpr: Expression = null;
            if (match([TokenType.COMMA])) {
                charExpr = parseExpression();
            }
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new PadStartFunctionCall(stringExpr, lengthExpr, charExpr);
        } else if (name == "padEnd") {
            consume(TokenType.LPAREN, "Expected '(' after 'padEnd'");
            var stringExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after string argument in 'padEnd'");
            var lengthExpr: Expression = parseExpression();
            var charExpr: Expression = null;
            if (match([TokenType.COMMA])) {
                charExpr = parseExpression();
            }
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new PadEndFunctionCall(stringExpr, lengthExpr, charExpr);
        } else if (name == "regex") {
            consume(TokenType.LPAREN, "Expected '(' after 'regex'");
            var patternExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after pattern argument in 'regex'");
            var flagsExpr: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new RegexFunctionCall(patternExpr, flagsExpr);
        } else if (name == "regexMatch") {
            consume(TokenType.LPAREN, "Expected '(' after 'regexMatch'");
            var regexExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after regex argument in 'regexMatch'");
            var stringExpr: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new RegexMatchFunctionCall(regexExpr, stringExpr);
        } else if (name == "regexReplace") {
            consume(TokenType.LPAREN, "Expected '(' after 'regexReplace'");
            var regexExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after regex argument in 'regexReplace'");
            var stringExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after string argument in 'regexReplace'");
            var replacementExpr: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new RegexReplaceFunctionCall(regexExpr, stringExpr, replacementExpr);
        } else if (name == "isEmpty") {
            consume(TokenType.LPAREN, "Expected '(' after 'isEmpty'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new IsEmptyFunctionCall(argument);
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
                if (property.value == "new") {
                    obj = new NewExpression(obj);
                } else if (property.value == "length") {
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

class ExpressionParser {
    private var tokens: Array<Token>;
    private var current: Int = 0;

    public function new(source: String) {
        this.tokens = Lexer.tokenize(source);
    }

    public function parseExpression(): Expression {
        return parseTernaryExpression();
    }

    private function parseTernaryExpression(): Expression {
        var expr = parseLogicalOr();
        if (match([TokenType.QUESTION])) {
            var trueBranch = parseExpression();
            consume(TokenType.COLON, "Expected ':' after '?'");
            var falseBranch = parseExpression();
            return new TernaryExpression(expr, trueBranch, falseBranch);
        }
        return expr;
    }

    private function parseLogicalOr(): Expression {
        var expr = parseLogicalAnd();
        while (match([TokenType.OR])) {
            var opera = previous().value;
            var right = parseLogicalAnd();
            expr = new BinaryExpression(expr, opera, right);
        }
        return expr;
    }

    private function parseLogicalAnd(): Expression {
        var expr = parseEquality();
        while (match([TokenType.AND])) {
            var opera = previous().value;
            var right = parseEquality();
            expr = new BinaryExpression(expr, opera, right);
        }
        return expr;
    }

    private function parseEquality(): Expression {
        var expr = parseComparison();
        while (match([TokenType.EQUAL_EQUAL, TokenType.BANG_EQUAL])) {
            var opera = previous().value;
            var right = parseComparison();
            expr = new BinaryExpression(expr, opera, right);
        }
        return expr;
    }

    private function parseComparison(): Expression {
        var expr = parseTerm();
        while (match([TokenType.GREATER, TokenType.GREATER_EQUAL, TokenType.LESS, TokenType.LESS_EQUAL])) {
            var opera = previous().value;
            var right = parseTerm();
            expr = new BinaryExpression(expr, opera, right);
        }
        return expr;
    }

    private function parseTerm(): Expression {
        var expr = parseFactor();
        while (match([TokenType.PLUS, TokenType.MINUS])) {
            var opera = previous().value;
            var right = parseFactor();
            expr = new BinaryExpression(expr, opera, right);
        }
        return expr;
    }

    private function parseFactor(): Expression {
        var expr = parseUnary();
        while (match([TokenType.MULTIPLY, TokenType.DIVIDE, TokenType.MODULO])) {
            var opera = previous().value;
            var right = parseUnary();
            expr = new BinaryExpression(expr, opera, right);
        }
        return expr;
    }

    private function parseUnary(): Expression {
        if (match([TokenType.NOT])) {
            var operand = parseUnary();
            return new UnaryExpression(previous().value, operand, true);
        } else if (match([TokenType.MINUS])) {
            var operand = parseUnary();
            return new UnaryExpression(previous().value, operand, true);
        }
        return parsePrimary();
    }

    private function parsePrimary(): Expression {
        if (match([TokenType.NUMBER])) {
            var value = previous().value;
            return new LiteralExpression(value.indexOf(".") != -1 ? Std.parseFloat(value) : Std.parseInt(value));
        } else if (match([TokenType.STRING])) {
            return new LiteralExpression(previous().value);
        } else if (match([TokenType.IDENTIFIER])) {
            return parseIdentifierOrCall();
        } else if (match([TokenType.TRUE])) {
            return new LiteralExpression(true);
        } else if (match([TokenType.FALSE])) {
            return new LiteralExpression(false);
        } else if (match([TokenType.NULL])) {
            return new LiteralExpression(null);
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
        } else if (match([TokenType.HTTP])) {
            consume(TokenType.LPAREN, "Expected '('");
            consume(TokenType.RPAREN, "Expected ')'");
            return parseHttpExpression();
        } else if (match([TokenType.DATE])) {
            consume(TokenType.LPAREN, "Expected '('");
            consume(TokenType.RPAREN, "Expected ')'");
            return parseDateExpression();
        } else if (match([TokenType.LPAREN])) {
            var expr = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return expr;
        }

        Flow.error.report("Unexpected token: " + peek().value, peek().lineNumber);
        return null;
    }

    private function parseIdentifierOrCall(): Expression {
        var name = previous().value;
        if (check(TokenType.LPAREN)) {
            return parseCallExpression(name);
        } else if (match([TokenType.DOT])) {
            return parsePropertyAccess(new VariableExpression(name));
        }
        return new VariableExpression(name);
    }

    private function parsePropertyAccess(object: Expression): Expression {
        var obj:Expression = new VariableExpression(previous().value);
        while (match([TokenType.DOT, TokenType.LBRACKET])) {
            if (peek().type == TokenType.DOT) {
                var property:Token = consume(TokenType.IDENTIFIER, "Expected property name");
                if (property.value == "new") {
                    obj = new NewExpression(obj);
                } else if (property.value == "length") {
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

        switch (methodName) {
            case ".nextInt":
                var lparenToken:Token = advance();
                if (lparenToken.type != TokenType.LPAREN) {
                    Flow.error.report("Expected '(' after method name", peek().lineNumber);
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
            case ".choice":
                var lparenToken:Token = advance();
                if (lparenToken.type != TokenType.LPAREN) {
                    Flow.error.report("Expected '(' after method name", peek().lineNumber);
                    return null;
                }
                var listExpr:Expression = parseExpression();
                var rparenToken:Token = advance();
                if (rparenToken.type != TokenType.RPAREN) {
                    Flow.error.report("Expected ')' after list", peek().lineNumber);
                    return null;
                }
                return new RandomExpression(methodName, [listExpr]);
            case ".weightedChoice":
                var lparenToken:Token = advance();
                if (lparenToken.type != TokenType.LPAREN) {
                    Flow.error.report("Expected '(' after method name", peek().lineNumber);
                    return null;
                }
                var listExpr:Expression = parseExpression();
                var commaToken:Token = advance();
                if (commaToken.type != TokenType.COMMA) {
                    Flow.error.report("Expected ',' after list", peek().lineNumber);
                    return null;
                }
                var weightsExpr:Expression = parseExpression();
                var rparenToken:Token = advance();
                if (rparenToken.type != TokenType.RPAREN) {
                    Flow.error.report("Expected ')' after weights", peek().lineNumber);
                    return null;
                }
                return new RandomExpression(methodName, [listExpr, weightsExpr]);
            case ".shuffle":
                var lparenToken:Token = advance();
                if (lparenToken.type != TokenType.LPAREN) {
                    Flow.error.report("Expected '(' after method name", peek().lineNumber);
                    return null;
                }
                var listExpr:Expression = parseExpression();
                var rparenToken:Token = advance();
                if (rparenToken.type != TokenType.RPAREN) {
                    Flow.error.report("Expected ')' after list", peek().lineNumber);
                    return null;
                }
                return new RandomExpression(methodName, [listExpr]);
            case ".sample":
                var lparenToken:Token = advance();
                if (lparenToken.type != TokenType.LPAREN) {
                    Flow.error.report("Expected '(' after method name", peek().lineNumber);
                    return null;
                }
                var listExpr:Expression = parseExpression();
                var commaToken:Token = advance();
                if (commaToken.type != TokenType.COMMA) {
                    Flow.error.report("Expected ',' after list", peek().lineNumber);
                    return null;
                }
                var nExpr:Expression = parseExpression();
                var rparenToken:Token = advance();
                if (rparenToken.type != TokenType.RPAREN) {
                    Flow.error.report("Expected ')' after sample size", peek().lineNumber);
                    return null;
                }
                return new RandomExpression(methodName, [listExpr, nExpr]);
            case ".gaussian":
                var lparenToken:Token = advance();
                if (lparenToken.type != TokenType.LPAREN) {
                    Flow.error.report("Expected '(' after method name", peek().lineNumber);
                    return null;
                }
                var meanExpr:Expression = parseExpression();
                var commaToken:Token = advance();
                if (commaToken.type != TokenType.COMMA) {
                    Flow.error.report("Expected ',' after mean", peek().lineNumber);
                    return null;
                }
                var stddevExpr:Expression = parseExpression();
                var rparenToken:Token = advance();
                if (rparenToken.type != TokenType.RPAREN) {
                    Flow.error.report("Expected ')' after standard deviation", peek().lineNumber);
                    return null;
                }
                return new RandomExpression(methodName, [meanExpr, stddevExpr]);
            default:
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
        } else if (methodName == ".args") {
            consume(TokenType.LPAREN, "Expected '(' after 'exit'");
            consume(TokenType.RPAREN, "Expected ')' after 'exit'");
            return new SystemExpression("args");
        } else {
            Flow.error.report("Unknown System method: " + methodName, peek().lineNumber);
            return null;
        }
    }

    private function parseFileExpression():Expression {
        var methodNameToken:Token = advance();
        var methodName:String = methodNameToken.value;
    
        switch (methodName) {
            case ".readFile":
                consume(TokenType.LPAREN, "Expected '(' after 'readFile'");
                var filePath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after file path expression");
                return new FileExpression("readFile", [filePath]);
            case ".writeFile":
                consume(TokenType.LPAREN, "Expected '(' after 'writeFile'");
                var filePath:Expression = parseExpression();
                consume(TokenType.COMMA, "Expected ',' after file path expression");
                var content:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after content expression");
                return new FileExpression("writeFile", [filePath, content]);
            case ".exists":
                consume(TokenType.LPAREN, "Expected '(' after 'exists'");
                var filePath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after file path expression");
                return new FileExpression("exists", [filePath]);
            case ".appendToFile":
                consume(TokenType.LPAREN, "Expected '(' after 'appendToFile'");
                var appendFilePath:Expression = parseExpression();
                consume(TokenType.COMMA, "Expected ',' after file path expression");
                var appendContent:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after content expression");
                return new FileExpression("appendToFile", [appendFilePath, appendContent]);
            case ".deleteFile":
                consume(TokenType.LPAREN, "Expected '(' after 'deleteFile'");
                var deleteFilePath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after file path expression");
                return new FileExpression("deleteFile", [deleteFilePath]);
            case ".copyFile":
                consume(TokenType.LPAREN, "Expected '(' after 'copyFile'");
                var sourcePath:Expression = parseExpression();
                consume(TokenType.COMMA, "Expected ',' after source path expression");
                var destinationPath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after destination path expression");
                return new FileExpression("copyFile", [sourcePath, destinationPath]);
            case ".renameFile":
                consume(TokenType.LPAREN, "Expected '(' after 'renameFile'");
                var oldPath:Expression = parseExpression();
                consume(TokenType.COMMA, "Expected ',' after old path expression");
                var newPath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after new path expression");
                return new FileExpression("renameFile", [oldPath, newPath]);
            case ".readLines":
                consume(TokenType.LPAREN, "Expected '(' after 'readLines'");
                var linesFilePath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after file path expression");
                return new FileExpression("readLines", [linesFilePath]);
            case ".getFileSize":
                consume(TokenType.LPAREN, "Expected '(' after 'getFileSize'");
                var fileSizePath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after file path expression");
                return new FileExpression("getFileSize", [fileSizePath]);
            case ".listFilesInDirectory":
                consume(TokenType.LPAREN, "Expected '(' after 'listFilesInDirectory'");
                var directoryPath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after directory path expression");
                return new FileExpression("listFilesInDirectory", [directoryPath]);
            case ".createDirectory":
                consume(TokenType.LPAREN, "Expected '(' after 'createDirectory'");
                var directoryPath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after directory path expression");
                return new FileExpression("createDirectory", [directoryPath]);
            case ".getFileExtension":
                consume(TokenType.LPAREN, "Expected '(' after 'getFileExtension'");
                var filePath:Expression = parseExpression();
                consume(TokenType.RPAREN, "Expected ')' after file path expression");
                return new FileExpression("getFileExtension", [filePath]);
            default:
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
            { name: ".atan", args: 1 },
            { name: ".floor", args: 1 },
            { name: ".round", args: 1 },
            { name: ".ceil", args: 1 },
            { name: ".trunc", args: 1 },
            { name: ".random", args: 0 }
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

    private function parseHttpExpression():Expression {
        var methodNameToken:Token = advance();
        var methodName:String = methodNameToken.value;

        if (methodName == ".get") {
            consume(TokenType.LPAREN, "Expected '(' after 'get'");
            var urlExpression:Expression = parseExpression();
            var headers:Map<String, String> = new Map<String, String>();
            if (match([TokenType.COMMA])) {
                consume(TokenType.LBRACE, "Expected '{' for headers");
                while (!check(TokenType.RBRACE)) {
                    var headerKey:Token = advance();
                    consume(TokenType.COLON, "Expected ':' after header key");
                    var headerValue:Expression = parseExpression();
                    headers.set(headerKey.value, headerValue.evaluate());
                    if (!match([TokenType.COMMA])) {
                        break;
                    }
                }
                consume(TokenType.RBRACE, "Expected '}' after headers");
            }
            consume(TokenType.RPAREN, "Expected ')' after expression(s)");
            return new HttpExpression("get", urlExpression, null, headers);
        } else if (methodName == ".post") {
            consume(TokenType.LPAREN, "Expected '(' after 'post'");
            var urlExpression:Expression = parseExpression();
            var dataExpression:Expression = null;
            if (match([TokenType.COMMA])) {
                dataExpression = parseExpression();
            }
            var headers:Map<String, String> = new Map<String, String>();
            if (match([TokenType.COMMA])) {
                consume(TokenType.LBRACE, "Expected '{' for headers");
                while (!check(TokenType.RBRACE)) {
                    var headerKey:Token = advance();
                    consume(TokenType.COLON, "Expected ':' after header key");
                    var headerValue:Expression = parseExpression();
                    headers.set(headerKey.value, headerValue.evaluate());
                    if (!match([TokenType.COMMA])) {
                        break;
                    }
                }
                consume(TokenType.RBRACE, "Expected '}' after headers");
            }
            consume(TokenType.RPAREN, "Expected ')' after expression(s)");
            return new HttpExpression("post", urlExpression, dataExpression, headers);
        } else {
            Flow.error.report("Unknown HTTP method: " + methodName, peek().lineNumber);
            return null;
        }
    }

    private function parseDateExpression():Expression {
        var methodNameToken:Token = advance();
        var methodName:String = methodNameToken.value;

        if (methodName == ".getCurrentDateTime") {
            consume(TokenType.LPAREN, "Expected '(' after 'getCurrentDateTime'");
            consume(TokenType.RPAREN, "Expected ')' after 'getCurrentDateTime'");
            return new DateExpression("getCurrentDateTime");
        } else if (methodName == ".getCurrentDate") {
            consume(TokenType.LPAREN, "Expected '(' after 'getCurrentDate'");
            consume(TokenType.RPAREN, "Expected ')' after 'getCurrentDate'");
            return new DateExpression("getCurrentDate");
        } else if (methodName == ".getCurrentTime") {
            consume(TokenType.LPAREN, "Expected '(' after 'getCurrentTime'");
            consume(TokenType.RPAREN, "Expected ')' after 'getCurrentTime'");
            return new DateExpression("getCurrentTime");
        } else if (methodName == ".formatDate") {
            consume(TokenType.LPAREN, "Expected '(' after 'formatDate'");
            var dateExpression:Expression = parseExpression();
            var formatExpression:Expression = null;
            if (match([TokenType.COMMA])) {
                formatExpression = parseExpression();
            }
            consume(TokenType.RPAREN, "Expected ')' after expression");
            if (formatExpression != null) {
                return new DateExpression("formatDate", [dateExpression, formatExpression]);
            } else {
                return new DateExpression("formatDate", [dateExpression]);
            }
        } else if (methodName == ".formatTime") {
            consume(TokenType.LPAREN, "Expected '(' after 'formatTime'");
            var timeExpression:Expression = parseExpression();
            var formatExpression:Expression = null;
            if (match([TokenType.COMMA])) {
                formatExpression = parseExpression();
            }
            consume(TokenType.RPAREN, "Expected ')' after expression");
            if (formatExpression != null) {
                return new DateExpression("formatTime", [timeExpression, formatExpression]);
            } else {
                return new DateExpression("formatTime", [timeExpression]);
            }
        } else if (methodName == ".fromString") {
            consume(TokenType.LPAREN, "Expected '(' after 'fromString'");
            var expression:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return new DateExpression("fromString", [expression]);
        } else if (methodName == ".diffInSeconds") {
            consume(TokenType.LPAREN, "Expected '(' after 'diffInSeconds'");
            var expr1:Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' between dates in 'diffInSeconds'");
            var expr2:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after second date");
            return new DateExpression("diffInSeconds", [expr1, expr2]);
        } else {
            Flow.error.report("Unknown Date method: " + methodName, peek().lineNumber);
            return null;
        }
    }

    private function parseCallExpression(name: String): Expression {
        var args: Array<Expression> = [];

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
        } else if (name == "remove") {
            consume(TokenType.LPAREN, "Expected '(' after 'remove'");
            var array: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after array argument in 'remove'");
            var element: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after element argument in 'remove'");
            var variableToken: Token = consume(TokenType.IDENTIFIER, "Expected variable name after ','");
            consume(TokenType.RPAREN, "Expected ')' after arguments in 'remove'");
            var variable: String = variableToken.value;
            return new RemoveFunctionCall(array, element, variable);            
        } else if (name == "str") {
            consume(TokenType.LPAREN, "Expected '(' after 'str'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new StrFunctionCall(argument);
        } else if (name == "int") {
            consume(TokenType.LPAREN, "Expected '(' after 'int'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new IntFunctionCall(argument);
        } else if (name == "float") {
            consume(TokenType.LPAREN, "Expected '(' after 'float'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new FloatFunctionCall(argument);
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
        } else if (name == "parseInt") {
            consume(TokenType.LPAREN, "Expected '(' after 'parseInt'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new IntFunctionCall(argument);
        } else if (name == "parseFloat") {
            consume(TokenType.LPAREN, "Expected '(' after 'parseFloat'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new FloatFunctionCall(argument);
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
        } else if (name == "exists") {
            consume(TokenType.LPAREN, "Expected '(' after 'exists'");
            var targetExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after target expression in 'exists'");
            var keyExpr: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after key expression in 'exists'");
            return new ExistsFunctionCall(targetExpr, keyExpr);
        } else if (name == "sort") {
            consume(TokenType.LPAREN, "Expected '(' after 'sort'");
            var arrayExpr: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after array argument in 'sort'");
            return new SortFunctionCall(arrayExpr);
        } else if (name == "capitalize") {
            consume(TokenType.LPAREN, "Expected '(' after 'capitalize'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new CapitalizeFunctionCall(argument);
        } else if (name == "reverse") {
            consume(TokenType.LPAREN, "Expected '(' after 'reverse'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new ReverseFunctionCall(argument);
        } else if (name == "isDigit") {
            consume(TokenType.LPAREN, "Expected '(' after 'isDigit'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new IsDigitFunctionCall(argument);
        } else if (name == "isNumeric") {
            consume(TokenType.LPAREN, "Expected '(' after 'isNumeric'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new IsNumericFunctionCall(argument);
        } else if (name == "center") {
            consume(TokenType.LPAREN, "Expected '(' after 'center'");
            var argument: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after argument");
            var width: Expression = parseExpression();
            var fillChar: Expression = null;
            if (match([TokenType.COMMA])) {
                fillChar = parseExpression();
            }
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new CenterFunctionCall(argument, width, fillChar);
        } else if (name == "count") {
            consume(TokenType.LPAREN, "Expected '(' after 'count'");
            var argument: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after first argument");
            var target: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new CountFunctionCall(argument, target);
        } else if (name == "calculate") {
            consume(TokenType.LPAREN, "Expected '(' after 'eval'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new CalculateFunctionCall(argument);
        } else if (name == "repeat") {
            consume(TokenType.LPAREN, "Expected '(' after 'repeat'");
            var stringArgument:Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after string argument");
            var countArgument:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new RepeatFunctionCall(stringArgument, countArgument);
        } else if (name == "range") {
            consume(TokenType.LPAREN, "Expected '(' after 'range'");
            var start: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after start argument");
            var end: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new RangeExpression(start, end);
        } else if (name == "padStart") {
            consume(TokenType.LPAREN, "Expected '(' after 'padStart'");
            var stringExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after string argument in 'padStart'");
            var lengthExpr: Expression = parseExpression();
            var charExpr: Expression = null;
            if (match([TokenType.COMMA])) {
                charExpr = parseExpression();
            }
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new PadStartFunctionCall(stringExpr, lengthExpr, charExpr);
        } else if (name == "padEnd") {
            consume(TokenType.LPAREN, "Expected '(' after 'padEnd'");
            var stringExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after string argument in 'padEnd'");
            var lengthExpr: Expression = parseExpression();
            var charExpr: Expression = null;
            if (match([TokenType.COMMA])) {
                charExpr = parseExpression();
            }
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new PadEndFunctionCall(stringExpr, lengthExpr, charExpr);
        } else if (name == "regex") {
            consume(TokenType.LPAREN, "Expected '(' after 'regex'");
            var patternExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after pattern argument in 'regex'");
            var flagsExpr: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new RegexFunctionCall(patternExpr, flagsExpr);
        } else if (name == "regexMatch") {
            consume(TokenType.LPAREN, "Expected '(' after 'regexMatch'");
            var regexExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after regex argument in 'regexMatch'");
            var stringExpr: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new RegexMatchFunctionCall(regexExpr, stringExpr);
        } else if (name == "regexReplace") {
            consume(TokenType.LPAREN, "Expected '(' after 'regexReplace'");
            var regexExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after regex argument in 'regexReplace'");
            var stringExpr: Expression = parseExpression();
            consume(TokenType.COMMA, "Expected ',' after string argument in 'regexReplace'");
            var replacementExpr: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new RegexReplaceFunctionCall(regexExpr, stringExpr, replacementExpr);
        } else if (name == "isEmpty") {
            consume(TokenType.LPAREN, "Expected '(' after 'isEmpty'");
            var argument: Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after argument");
            return new IsEmptyFunctionCall(argument);
        }

        var isMethodCall: Bool = name.indexOf(".") > -1;
        if (isMethodCall) {
            var parts: Array<String> = name.split(".");
            var objectName: String = parts.shift();
            var methodName: String = parts.join(".");
            consume(TokenType.LPAREN, "Expected '(' after method name");
            while (!check(TokenType.RPAREN)) {
                args.push(parseExpression());
                if (match([TokenType.COMMA])) {
                    // Consume comma
                }
            }
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new MethodCallExpression(objectName, methodName, args);
        } else {
            consume(TokenType.LPAREN, "Expected '(' after function name");
            while (!check(TokenType.RPAREN)) {
                args.push(parseExpression());
                if (match([TokenType.COMMA])) {
                    // Consume comma
                }
            }
            consume(TokenType.RPAREN, "Expected ')' after arguments");
            return new CallExpression(name, args);
        }
    }

    private function match(types: Array<TokenType>): Bool {
        for (type in types) {
            if (check(type)) {
                advance();
                return true;
            }
        }
        return false;
    }

    private function check(type: TokenType): Bool {
        if (isAtEnd()) return false;
        return peek().type == type;
    }

    private function advance(): Token {
        if (!isAtEnd()) current++;
        return previous();
    }

    private function consume(type: TokenType, message: String): Token {
        if (check(type)) return advance();
        Flow.error.report(message, peek().lineNumber);
        return null;
    }

    private function isAtEnd(): Bool {
        return current >= tokens.length;
    }

    private function peek(): Token {
        return tokens[current];
    }

    private function previous(): Token {
        return tokens[current - 1];
    }
}
