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
            } else {
                Flow.error.report("Unknown keyword: " + keyword);
                return null;
            }
        } else if (firstTokenType == TokenType.IDENTIFIER) {
            return parseLetStatement();
        } else {
            Flow.error.report("Unexpected token: " + peek().value);
            return null;
        }
    }

    private function parseLetStatement(): LetStatement {
        var nameToken: Token = consume(TokenType.IDENTIFIER, "Expected variable name after 'let'");
        var name: String = nameToken.value;
    
        consume(TokenType.EQUAL, "Expected '=' after variable name");
    
        var initializer: Expression;

        if (check(TokenType.LBRACKET)) {
            initializer = parseArrayLiteral();
        } else {
            initializer = parseExpression();
        }
    
        return new LetStatement(name, initializer);
    }
    
    private function parseArrayLiteral(): Expression {
        consume(TokenType.LBRACKET, "Expected '[' to start array literal");
    
        var elements: Array<Expression> = [];
    
        while (!check(TokenType.RBRACKET) && !isAtEnd()) {
            var element: Expression = parseExpression();
            elements.push(element);
    
            if (match([TokenType.COMMA])) {
                if (check(TokenType.RBRACKET)) {
                    break;
                }
            }
        }
    
        consume(TokenType.RBRACKET, "Expected ']' after array literal");
    
        return new ArrayLiteralExpression(elements);
    }

    private function parsePrintStatement():PrintStatement {
        consume(TokenType.LPAREN, "Expected '(' after 'print'");
        var expression:Expression = parseExpression();
        consume(TokenType.RPAREN, "Expected ')' after expression");
        return new PrintStatement(expression);
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
    
        var body:Statement;
        if (check(TokenType.LBRACE)) {
            body = parseBlock();
        } else {
            body = parseStatement();
        }
    
        return new ForStatement(variableName, iterableExpression, body);
    }

    private function parseFuncStatement():FuncStatement {
        var nameToken:Token = consume(TokenType.IDENTIFIER, "Expected function name after 'func'");
        var name:String = nameToken.value;

        consume(TokenType.LPAREN, "Expected '(' after function name");

        var parameters:Array<String> = [];
        while (!check(TokenType.RPAREN)) {
            var parameterToken:Token = consume(TokenType.IDENTIFIER, "Expected parameter name");
            parameters.push(parameterToken.value);
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

    private function parseReturnStatement(): Statement {
        var expression:Expression = parseExpression();
        return new ReturnStatement(expression);
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
        return parseAssignment();
    }
    
    private function parseAssignment():Expression {
        var expr = parseEquality();

        if (match([TokenType.EQUAL])) {
            var equals = previous();
            var value = parseAssignment();

            if (Std.is(expr, VariableExpression)) {
                var name = (cast expr : VariableExpression).name;
                return new AssignExpression(name, value);
            }

            Flow.error.report("Invalid assignment target");
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
    
    private function parseComparison():Expression {
        var expr = parseTerm();

        while (match([TokenType.GREATER, TokenType.GREATER_EQUAL, TokenType.LESS, TokenType.LESS_EQUAL])) {
            var opera = previous().value;
            var right = parseTerm();
            expr = new BinaryExpression(expr, opera, right);
        }

        return expr;
    }

    private function parseTerm():Expression {
        var expr = parseFactor();
    
        while (match([TokenType.PLUS, TokenType.MINUS])) {
            var opera = previous().value;
            var right = parseFactor();
            expr = new BinaryExpression(expr, opera, right);
        }
    
        return expr;
    }

    private function parseRange():Expression {
        var expr:Expression = parseTerm();
        while (match([TokenType.RANGE])) {
            var opera:String = previous().value;
            var endExpr:Expression = parseTerm();
            expr = new RangeExpression(expr, endExpr);
        }
        return expr;
    }

    private function parseFactor():Expression {
        if (match([TokenType.NUMBER])) {
            var value:String = previous().value;
            if (value.indexOf(".") != -1) {
              return new LiteralExpression(Std.parseFloat(value));
            } else {
              return new LiteralExpression(Std.parseInt(value));
            }
        } else if (match([TokenType.STRING])) {
            return new LiteralExpression(previous().value);
        } else if (match([TokenType.IDENTIFIER])) {
            if (peek().type == TokenType.LPAREN) {
                return parseCallExpression();
            } else {
                return new VariableExpression(previous().value);
            }
        } else if (match([TokenType.TRUE])) {
            return new LiteralExpression(true);
        } else if (match([TokenType.FALSE])) {
            return new LiteralExpression(false);
        } else if (match([TokenType.LPAREN])) {
            var expr:Expression = parseExpression();
            consume(TokenType.RPAREN, "Expected ')' after expression");
            return expr;
        } else {
            Flow.error.report("Unexpected token: " + peek().value);
            return null;
        }
    }

    private function parseCallExpression():Expression {
        var nameToken:Token = previous();
        var name:String = nameToken.value;
        var arguments:Array<Expression> = [];
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

    private function advance():Token {
        currentTokenIndex++;
        return previous();
    }

    private function isAtEnd():Bool {
        return currentTokenIndex >= tokens.length;
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
            Flow.error.report(message);
        }
        return advance();
    }
}
