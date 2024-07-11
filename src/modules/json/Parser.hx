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
        return this.parseValue();
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
                throw "Unexpected token: " + this.currentToken.type;
        }
    }

    private function parseObject():Dynamic {
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
    }

    private function parseArray():Dynamic {
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
    }

    private function parseString():String {
        if (this.currentToken.type != TokenType.STRING) {
            throw "Expected string, got " + this.currentToken.type;
        }
        var str = this.currentToken.value;
        this.currentToken = this.lexer.getNextToken();
        return str;
    }

    private function expect(type:TokenType):Void {
        if (this.currentToken.type != type) {
            throw "Expected " + type + ", got " + this.currentToken.type;
        }
        this.currentToken = this.lexer.getNextToken();
    }
}
