package modules.json;

class Lexer {
    public var input:String;
    public var position:Int;
    public var currentChar:Null<String>;

    public function new(input:String) {
        this.input = input;
        this.position = 0;
        this.currentChar = null;
        this.readNextChar();
    }

    private function readNextChar():Void {
        if (this.position < this.input.length) {
            this.currentChar = this.input.charAt(this.position);
            this.position++;
        } else {
            this.currentChar = null;
        }
        if (this.currentChar == ' ' || this.currentChar == '\t' || this.currentChar == '\n' || this.currentChar == '\r') {
            this.readNextChar();
        }
    }

    public function getNextToken():Token {
        while (this.currentChar != null) {
            switch (this.currentChar) {
                case '{':
                    this.readNextChar();
                    return new Token(TokenType.LEFT_BRACE, "{");
                case '}':
                    this.readNextChar();
                    return new Token(TokenType.RIGHT_BRACE, "}");
                case '[':
                    this.readNextChar();
                    return new Token(TokenType.LEFT_BRACKET, "[");
                case ']':
                    this.readNextChar();
                    return new Token(TokenType.RIGHT_BRACKET, "]");
                case ',':
                    this.readNextChar();
                    return new Token(TokenType.COMMA, ",");
                case ':':
                    this.readNextChar();
                    return new Token(TokenType.COLON, ":");
                case ' ':
                case '\t':
                case '\n':
                case '\r':
                    this.readNextChar();
                    continue;
                case '"':
                    return this.readString();
                default:
                    if (this.isDigit(this.currentChar)) {
                        return this.readNumber();
                    } else if (this.isAlpha(this.currentChar)) {
                        return this.readIdentifier();
                    } else {
                        Flow.error.report("Unexpected character: " + this.currentChar);
                        return new Token(TokenType.EOF, "");
                    }
            }
        }
        return new Token(TokenType.EOF, "");
    }

    private function readString():Token {
        try {
            var result:String = "";
            this.readNextChar();
            while (this.currentChar!= null && this.currentChar!= '"') {
                if (this.currentChar == '\\') {
                    this.readNextChar();
                    switch (this.currentChar) {
                        case 'n':
                            result += '\n';
                        case 't':
                            result += '\t';
                        case 'r':
                            result += '\r';
                        case 'u':
                            var hex = "";
                            var hexReg = ~/^[0-9a-fA-F]$/;
                            for (i in 0...4) {
                                this.readNextChar();
                                if (this.currentChar == null || !hexReg.match(this.currentChar)) {
                                    Flow.error.report("Invalid Unicode escape sequence");
                                    return new Token(TokenType.EOF, "");
                                }
                                hex += this.currentChar;
                            }
                            result += String.fromCharCode(Std.parseInt("0x" + hex));
                        case '"':
                            result += '"';
                        case '\\':
                            result += '\\';
                        default:
                            Flow.error.report("Invalid escape sequence: \\" + this.currentChar);
                            return new Token(TokenType.EOF, "");
                    }
                } else {
                    result += this.currentChar;
                }
                this.readNextChar();
            }
            if (this.currentChar!= '"') {
                Flow.error.report("Unclosed string");
                return new Token(TokenType.EOF, "");
            }
            this.readNextChar();
            return new Token(TokenType.STRING, result);
        } catch (e:Dynamic) {
            Flow.error.report("Error reading string: " + e.toString());
            return new Token(TokenType.EOF, "");
        }
    }

    private function readNumber():Token {
        try {
            var result:String = "";
            while (this.currentChar != null && (this.isDigit(this.currentChar) || this.currentChar == '.')) {
                result += this.currentChar;
                this.readNextChar();
            }
            return new Token(TokenType.NUMBER, result);
        } catch (e:Dynamic) {
            Flow.error.report("Error reading number: " + e.toString());
            return new Token(TokenType.EOF, "");
        }
    }

    private function readIdentifier():Token {
        try {
            var result:String = "";
            while (this.currentChar != null && (this.isAlphaNumeric(this.currentChar))) {
                result += this.currentChar;
                this.readNextChar();
            }
            return new Token(TokenType.IDENTIFIER, result);
        } catch (e:Dynamic) {
            Flow.error.report("Error reading identifier: " + e.toString());
            return new Token(TokenType.EOF, "");
        }
    }

    private function isDigit(char:String):Bool {
        return char >= '0' && char <= '9';
    }

    private function isAlpha(char:String):Bool {
        return (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z');
    }

    private function isAlphaNumeric(char:String):Bool {
        return this.isAlpha(char) || this.isDigit(char);
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
    LEFT_BRACE;
    RIGHT_BRACE;
    LEFT_BRACKET;
    RIGHT_BRACKET;
    COMMA;
    COLON;
    STRING;
    NUMBER;
    IDENTIFIER;
    EOF;
}
