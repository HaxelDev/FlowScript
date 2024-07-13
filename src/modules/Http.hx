package modules;

class Http {
    private var url: String;
    private var headers: Map<String, String>;
    private var data: String;

    public function new(url: String) {
        this.url = url;
        this.headers = new Map();
        this.data = "";
    }

    public function setHeader(name: String, value: String): Void {
        this.headers.set(name, value);
    }

    public function setParameter(name: String, value: String): Void {
        if (this.data != "") {
            this.data += "&";
        }
        this.data += name + "=" + value;
    }

    public function request(method: String, onSuccess: String -> Void, onError: String -> Void): Void {
        var http = new haxe.Http(this.url);
        for (header in this.headers.keys()) {
            http.setHeader(header, this.headers.get(header));
        }
        if (method == "POST") {
            http.setPostData(this.data);
        }
        http.onData = function(response: String) {
            onSuccess(response);
        }
        http.onError = function(error: String) {
            onError(error);
        }
        http.request(true);
    }

    public function get(onSuccess: String -> Void, onError: String -> Void): Void {
        this.request("GET", onSuccess, onError);
    }

    public function post(onSuccess: String -> Void, onError: String -> Void): Void {
        this.request("POST", onSuccess, onError);
    }
}
