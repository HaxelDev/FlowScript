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
                        throw "Unexpected character: " + this.currentChar;
                    }
            }
        }
        return new Token(TokenType.EOF, "");
    }

    private function readString():Token {
        var result:String = "";
        this.readNextChar();
        while (this.currentChar != null && this.currentChar != '"') {
            result += this.currentChar;
            this.readNextChar();
        }
        this.readNextChar();
        return new Token(TokenType.STRING, result);
    }

    private function readNumber():Token {
        var result:String = "";
        while (this.currentChar != null && (this.isDigit(this.currentChar) || this.currentChar == '.')) {
            result += this.currentChar;
            this.readNextChar();
        }
        return new Token(TokenType.NUMBER, result);
    }

    private function readIdentifier():Token {
        var result:String = "";
        while (this.currentChar != null && (this.isAlphaNumeric(this.currentChar))) {
            result += this.currentChar;
            this.readNextChar();
        }
        return new Token(TokenType.IDENTIFIER, result);
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
