package modules.json;

import modules.json.Lexer;

class Parser {
    private var lexer:Lexer;
    private var currentToken:Token;

    public function new(lexer:Lexer) {
        this.lexer = lexer;
        this.currentToken = lexer.getNextToken();
    }

    public function parse():Dynamic {
        try {
            return this.parseValue();
        } catch (e:Dynamic) {
            Flow.error.report("Error parsing JSON: " + e.toString());
            return null;
        }
    }

    private function parseValue():Dynamic {
        switch (this.currentToken.type) {
            case TokenType.STRING:
                var str = this.currentToken.value;
                this.currentToken = this.lexer.getNextToken();
                return str;
            case TokenType.NUMBER:
                var num = Std.parseFloat(this.currentToken.value);
                this.currentToken = this.lexer.getNextToken();
                return num;
            case TokenType.IDENTIFIER:
                var ident = this.currentToken.value;
                this.currentToken = this.lexer.getNextToken();
                return ident;
            case TokenType.LEFT_BRACE:
                return this.parseObject();
            case TokenType.LEFT_BRACKET:
                return this.parseArray();
            default:
                Flow.error.report("Unexpected token: " + this.currentToken.type);
                return null;
        }
    }

    private function parseObject():Dynamic {
        try {
            var obj:Dynamic = {};
            this.currentToken = this.lexer.getNextToken();
            while (this.currentToken.type != TokenType.RIGHT_BRACE) {
                var key = this.parseString();
                this.expect(TokenType.COLON);
                var value = this.parseValue();
                Reflect.setField(obj, key, value);
                if (this.currentToken.type == TokenType.COMMA) {
                    this.currentToken = this.lexer.getNextToken();
                }
            }
            this.currentToken = this.lexer.getNextToken();
            return obj;
        } catch (e:Dynamic) {
            Flow.error.report("Error parsing object: " + e.toString());
            return null;
        }
    }

    private function parseArray():Dynamic {
        try {
            var arr:Array<Dynamic> = [];
            this.currentToken = this.lexer.getNextToken();
            while (this.currentToken.type != TokenType.RIGHT_BRACKET) {
                arr.push(this.parseValue());
                if (this.currentToken.type == TokenType.COMMA) {
                    this.currentToken = this.lexer.getNextToken();
                }
            }
            this.currentToken = this.lexer.getNextToken();
            return arr;
        } catch (e:Dynamic) {
            Flow.error.report("Error parsing array: " + e.toString());
            return null;
        }
    }

    private function parseString():String {
        try {
            if (this.currentToken.type != TokenType.STRING) {
                Flow.error.report("Expected string, got " + this.currentToken.type);
                return null;
            }
            var str = this.currentToken.value;
            this.currentToken = this.lexer.getNextToken();
            return str;
        } catch (e:Dynamic) {
            Flow.error.report("Error parsing string: " + e.toString());
            return null;
        }
    }

    private function expect(type:TokenType):Void {
        try {
            if (this.currentToken.type != type) {
                Flow.error.report("Expected " + type + ", got " + this.currentToken.type);
                return;
            }
            this.currentToken = this.lexer.getNextToken();
        } catch (e:Dynamic) {
            Flow.error.report("Error expecting token: " + e.toString());
        }
    }
}
