package flow;

class Lexer {
    public static var currentLine:Int = 1;

    static public function tokenize(code:String):Array<Token> {
        var tokens:Array<Token> = [];
        var currentToken:String = "";
        var inString:Bool = false;
        var stringDelimiter:String = "";
        var escapeSequence:Bool = false;
        var i:Int = 0;

        while (i < code.length) {
            var char:String = code.charAt(i);

            if (char == "\n") {
                currentLine++;
            } else if (char == "\"" || char == "'") {
                if (inString) {
                    if (currentToken.length > 0 && currentToken.charAt(currentToken.length - 1) == '\\') {
                        currentToken = currentToken.substring(0, currentToken.length - 1) + char;
                        escapeSequence = true;
                    } else if (char == stringDelimiter) {
                        tokens.push(new Token(TokenType.STRING, currentToken, currentLine));
                        currentToken = "";
                        inString = false;
                        stringDelimiter = "";
                    } else {
                        currentToken += char;
                    }
                } else {
                    inString = true;
                    stringDelimiter = char;
                }
                i++;
                continue;
            } else if (inString) {
                if (escapeSequence) {
                    switch (char) {
                        case "n":
                            currentToken += "\n";
                        case "t":
                            currentToken += "\t";
                        case "r":
                            currentToken += "\r";
                        case "\\":
                            currentToken += "\\";
                        case "\"":
                            currentToken += "\"";
                        case "'":
                            currentToken += "'";
                        default:
                            currentToken += "\\" + char;
                    }
                    escapeSequence = false;
                } else if (char == '\\') {
                    escapeSequence = true;
                } else {
                    currentToken += char;
                }
                i++;
                continue;
            } else if (char == "/" && i + 1 < code.length && code.charAt(i + 1) == "/") {
                while (i < code.length && code.charAt(i) != "\n") {
                    i++;
                }
                continue;
            } else if (isAlpha(char) || char == "_") {
                currentToken += char;
            } else if (isNumeric(char)) {
                currentToken += char;
            } else if (char == "(" || char == ")" || char == "{" || char == "}" ||
                char == "[" || char == "]" || char == "," || char == ":" ||
                char == "+" || char == "-" || char == "*" || char == "/" ||
                char == "=" || char == ">" || char == "<" || char == ";" ||
                char == "." || char == "!" || char == "%" || char == "?") {
                if (currentToken.length > 0) {
                    tokens.push(getToken(currentToken, currentLine));
                    currentToken = "";
                }
                var symbol:String = char;
                if (char == "=") {
                    if (i + 1 < code.length) {
                        var nextChar:String = code.charAt(i + 1);
                        if (nextChar == "=") {
                            symbol += nextChar;
                            i++;
                        } else if (nextChar == ">" || nextChar == "<") {
                            symbol += nextChar;
                            i++;
                        }
                    }
                } else if (char == "!" && i + 1 < code.length && code.charAt(i + 1) == "=") {
                    symbol += "=";
                    i++;
                } else if (char == ">" && i + 1 < code.length && code.charAt(i + 1) == "=") {
                    symbol += "=";
                    i++;
                } else if (char == "<" && i + 1 < code.length && code.charAt(i + 1) == "=") {
                    symbol += "=";
                    i++;
                } else if (char == "+" && i + 1 < code.length) {
                    var nextChar:String = code.charAt(i + 1);
                    if (nextChar == "=") {
                        symbol += "=";
                        i++;
                    } else if (nextChar == "+") {
                        symbol += "+";
                        i++;
                    }
                } else if (char == "-" && i + 1 < code.length) {
                    var nextChar:String = code.charAt(i + 1);
                    if (nextChar == "=") {
                        symbol += "=";
                        i++;
                    } else if (nextChar == "-") {
                        symbol += "-";
                        i++;
                    }
                }
                tokens.push(new Token(getSymbolType(symbol), symbol, currentLine));
            } else {
                if (currentToken.length > 0) {
                    tokens.push(getToken(currentToken, currentLine));
                    currentToken = "";
                }
            }
            i++;
        }

        if (currentToken.length > 0) {
            tokens.push(getToken(currentToken, currentLine));
        }

        return tokens;
    }

    static private function getToken(token:String, lineNumber:Int):Token {
        switch (token) {
            case "print":
                return new Token(TokenType.KEYWORD, token, lineNumber);
            case "let":
                return new Token(TokenType.KEYWORD, token, lineNumber);
            case "true":
                return new Token(TokenType.TRUE, token, lineNumber);
            case "false":
                return new Token(TokenType.FALSE, token, lineNumber);
            case "null":
                return new Token(TokenType.NULL, token, lineNumber);
            case "if":
                return new Token(TokenType.KEYWORD, token, lineNumber);
            case "else":
                return new Token(TokenType.KEYWORD, token, lineNumber);
            case "while":
                return new Token(TokenType.KEYWORD, token, lineNumber);
            case "for":
                return new Token(TokenType.KEYWORD, token, lineNumber);
            case "func":
                return new Token(TokenType.KEYWORD, token, lineNumber);
            case "call":
                return new Token(TokenType.KEYWORD, token, lineNumber);
            case "return":
                return new Token(TokenType.KEYWORD, token, lineNumber);
            case "break":
                return new Token(TokenType.KEYWORD, token, lineNumber);
            case "continue":
                return new Token(TokenType.KEYWORD, token, lineNumber);
            case "switch":
                return new Token(TokenType.KEYWORD, token, lineNumber);
            case "import":
                return new Token(TokenType.KEYWORD, token, lineNumber);
            case "try":
                return new Token(TokenType.KEYWORD, token, lineNumber);
            case "error":
                return new Token(TokenType.KEYWORD, token, lineNumber);
            case "catch":
                return new Token(TokenType.KEYWORD, token, lineNumber);
            case "enum":
                return new Token(TokenType.KEYWORD, token, lineNumber);
            case "do":
                return new Token(TokenType.KEYWORD, token, lineNumber);
            case "lambda":
                return new Token(TokenType.KEYWORD, token, lineNumber);
            case "in":
                return new Token(TokenType.IN, token, lineNumber);
            case "case":
                return new Token(TokenType.CASE, token, lineNumber);
            case "default":
                return new Token(TokenType.DEFAULT, token, lineNumber);
            case "IO":
                return new Token(TokenType.IO, token, lineNumber);
            case "Random":
                return new Token(TokenType.RANDOM, token, lineNumber);
            case "System":
                return new Token(TokenType.SYSTEM, token, lineNumber);
            case "File":
                return new Token(TokenType.FILE, token, lineNumber);
            case "Json":
                return new Token(TokenType.JSON, token, lineNumber);
            case "Math":
                return new Token(TokenType.MATH, token, lineNumber);
            case "Http":
                return new Token(TokenType.HTTP, token, lineNumber);
            case "Date":
                return new Token(TokenType.DATE, token, lineNumber);
            case "and":
                return new Token(TokenType.AND, token, lineNumber);
            case "or":
                return new Token(TokenType.OR, token, lineNumber);
            case "not":
                return new Token(TokenType.NOT, token, lineNumber);
            case "%":
                return new Token(TokenType.MODULO, token, lineNumber);
            case "<<":
                return new Token(TokenType.LEFT_SHIFT, token, lineNumber);
            case ">>":
                return new Token(TokenType.RIGHT_SHIFT, token, lineNumber);
            case "=":
                return new Token(TokenType.EQUAL, token, lineNumber);
            case "==":
                return new Token(TokenType.EQUAL_EQUAL, token, lineNumber);
            case "!=":
                return new Token(TokenType.BANG_EQUAL, token, lineNumber);
            case "+=":
                return new Token(TokenType.PLUS_EQUAL, token, lineNumber);
            case "-=":
                return new Token(TokenType.MINUS_EQUAL, token, lineNumber);
            case "++":
                return new Token(TokenType.PLUS_PLUS, token, lineNumber);
            case "--":
                return new Token(TokenType.MINUS_MINUS, token, lineNumber);
            case ">":
                return new Token(TokenType.GREATER, token, lineNumber);
            case ">=":
                return new Token(TokenType.GREATER_EQUAL, token, lineNumber);
            case "<":
                return new Token(TokenType.LESS, token, lineNumber);
            case "<=":
                return new Token(TokenType.LESS_EQUAL, token, lineNumber);
            case "*":
                return new Token(TokenType.MULTIPLY, token, lineNumber);
            case "/":
                return new Token(TokenType.DIVIDE, token, lineNumber);
            case ":":
                return new Token(TokenType.COLON, token, lineNumber);
            case "?":
                return new Token(TokenType.QUESTION, token, lineNumber);
            case ";":
                return new Token(TokenType.SEMICOLON, token, lineNumber);
            case "!":
                return new Token(TokenType.BANG, token, lineNumber);
            case "=>":
                return new Token(TokenType.ARROW, token, lineNumber);
            default:
                if (isNumeric(token)) {
                    return new Token(TokenType.NUMBER, token, lineNumber);
                } else {
                    return new Token(TokenType.IDENTIFIER, token, lineNumber);
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
            case "+=":
                return TokenType.PLUS_EQUAL;
            case "-=":
                return TokenType.MINUS_EQUAL;
            case "++":
                return TokenType.PLUS_PLUS;
            case "--":
                return TokenType.MINUS_MINUS;
            case ";":
                return TokenType.SEMICOLON;
            case "?":
                return TokenType.QUESTION;
            case "%":
                return TokenType.MODULO;
            case "=>":
                return TokenType.ARROW;
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
    public var lineNumber:Int;

    public function new(type:TokenType, value:String, lineNumber:Int) {
        this.type = type;
        this.value = value;
        this.lineNumber = lineNumber;
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
    NULL;
    AND;
    OR;
    IN;
    MODULO;
    LEFT_SHIFT;
    RIGHT_SHIFT;
    IO;
    RANDOM;
    SYSTEM;
    FILE;
    JSON;
    MATH;
    HTTP;
    DATE;
    DEFAULT;
    CASE;
    NOT;
    PLUS_EQUAL;
    MINUS_EQUAL;
    PLUS_PLUS;
    MINUS_MINUS;
    QUESTION;
    ARROW;
}
