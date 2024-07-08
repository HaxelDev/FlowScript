package flow;

class Lexer {
    static public function tokenize(code:String):Array<Token> {
        var tokens:Array<Token> = [];
        var currentToken:String = "";
        var inString:Bool = false;
        var i:Int = 0;

        while (i < code.length) {
            var char:String = code.charAt(i);

            if (char == "\"" || char == "'") {
                if (inString) {
                    tokens.push(new Token(TokenType.STRING, currentToken));
                    currentToken = "";
                    inString = false;
                } else {
                    inString = true;
                }
                i++;
                continue;
            }

            if (inString) {
                currentToken += char;
            } else if (isAlpha(char) || char == "_") {
                currentToken += char;
            } else if (isNumeric(char)) {
                currentToken += char;
            } else if (char == "(" || char == ")" || char == "{" || char == "}" ||
                char == "[" || char == "]" || char == "," || char == ":" ||
                char == "+" || char == "-" || char == "*" || char == "/" ||
                char == "=" || char == ">" || char == "<" || char == ";" ||
                (char == "." && i + 1 < code.length && code.charAt(i + 1) == ".")) {
                if (currentToken.length > 0) {
                    tokens.push(getToken(currentToken));
                    currentToken = "";
                }
                var symbol:String = char;
                if (char == "." && i + 1 < code.length && code.charAt(i + 1) == ".") {
                    symbol += ".";
                    i++;
                }
                tokens.push(new Token(getSymbolType(symbol), symbol));
            } else {
                if (currentToken.length > 0) {
                    tokens.push(getToken(currentToken));
                    currentToken = "";
                }
            }
            i++;
        }

        if (currentToken.length > 0) {
            tokens.push(getToken(currentToken));
        }

        return tokens;
    }

    static private function getToken(token:String):Token {
        switch (token) {
            case "print":
                return new Token(TokenType.KEYWORD, token);
            case "let":
                return new Token(TokenType.KEYWORD, token);
            case "true":
                return new Token(TokenType.TRUE, token);
            case "false":
                return new Token(TokenType.FALSE, token);
            case "if":
                return new Token(TokenType.KEYWORD, token);
            case "else":
                return new Token(TokenType.KEYWORD, token);
            case "while":
                return new Token(TokenType.KEYWORD, token);
            case "for":
                return new Token(TokenType.KEYWORD, token);
            case "in":
                return new Token(TokenType.IN, token);
            case "&&":
                return new Token(TokenType.AND, token);
            case "||":
                return new Token(TokenType.OR, token);
            case "&":
                return new Token(TokenType.BITWISE_AND, token);
            case "|":
                return new Token(TokenType.BITWISE_OR, token);
            case "^":
                return new Token(TokenType.BITWISE_XOR, token);
            case "<<":
                return new Token(TokenType.LEFT_SHIFT, token);
            case ">>":
                return new Token(TokenType.RIGHT_SHIFT, token);
            case "..":
                return new Token(TokenType.RANGE, token);
            default:
                if (isNumeric(token)) {
                    return new Token(TokenType.NUMBER, token);
                } else {
                    return new Token(TokenType.IDENTIFIER, token);
                }
        }
    }

    static private function getSymbolType(char:String):TokenType {
        switch (char) {
            case "(":
                return TokenType.LPAREN;
            case ")":
                return TokenType.RPAREN;
            case "{":
                return TokenType.LBRACE;
            case "}":
                return TokenType.RBRACE;
            case "[":
                return TokenType.LBRACKET;
            case "]":
                return TokenType.RBRACKET;
            case ",":
                return TokenType.COMMA;
            case ":":
                return TokenType.COLON;
            case "+":
                return TokenType.PLUS;
            case "-":
                return TokenType.MINUS;
            case "*":
                return TokenType.MULTIPLY;
            case "/":
                return TokenType.DIVIDE;
            case "=":
                return TokenType.EQUAL;
            case "==":
                return TokenType.EQUAL_EQUAL;
            case "!=":
                return TokenType.BANG_EQUAL;
            case ">":
                return TokenType.GREATER;
            case ">=":
                return TokenType.GREATER_EQUAL;
            case "<":
                return TokenType.LESS;
            case "<=":
                return TokenType.LESS_EQUAL;
            case ";":
                return TokenType.SEMICOLON;
            case "..":
                return TokenType.RANGE;
            default:
                return TokenType.SYMBOL;
        }
    }

    static private function isAlpha(char:String):Bool {
        var code:Int = char.charCodeAt(0);
        return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
    }

    static private function isNumeric(char:String):Bool {
        return Std.parseInt(char) != null || char == ".";
    }
}

class Token {
    public var type:TokenType;
    public var value:String;

    public function new(type:TokenType, value:String) {
        this.type = type;
        this.value = value;
    }
}

enum TokenType {
    KEYWORD;
    SYMBOL;
    STRING;
    LPAREN;
    RPAREN;
    LBRACE;
    RBRACE;
    LBRACKET;
    RBRACKET;
    COMMA;
    DOT;
    COLON;
    PLUS;
    MINUS;
    MULTIPLY;
    DIVIDE;
    EQUAL;
    IDENTIFIER;
    NUMBER;
    BANG;
    EQUAL_EQUAL;
    BANG_EQUAL;
    GREATER;
    GREATER_EQUAL;
    LESS;
    LESS_EQUAL;
    SEMICOLON;
    TRUE;
    FALSE;
    AND;
    OR;
    IN;
    RANGE;
    BITWISE_AND;
    BITWISE_OR;
    BITWISE_XOR;
    LEFT_SHIFT;
    RIGHT_SHIFT;
}
