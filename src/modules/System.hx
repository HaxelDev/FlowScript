package modules;

class System {
    public static function currentDate(): String {
        var date = Date.now();
        var year = date.getFullYear();
        var month = date.getMonth() + 1;
        var day = date.getDate();
        var hours = date.getHours();
        var minutes = date.getMinutes();
        var seconds = date.getSeconds();
        return year + "-" + pad(month) + "-" + pad(day) + " " + pad(hours) + ":" + pad(minutes) + ":" + pad(seconds);
    }

    private static function pad(number: Int): String {
        return number < 10 ? "0" + number : Std.string(number);
    }

    public static function openUrl (url:String) : Void {
        switch (Sys.systemName()) {
            case "Linux", "BSD": Sys.command("xdg-open", [url]);
            case "Mac": Sys.command("open", [url]);
            case "Windows": Sys.command("start", [url]);
            default:
        }
    }

    public static function exit(): Void {
        Sys.exit(0);
    }

    public static function println(message: String): Void {
        Sys.println(message);
    }

    public static function sleep(milliseconds: Int): Void {
        Sys.sleep(milliseconds / 1000);
    }

    public static function command(cmd: String): Void {
        var process = Sys.command(cmd);
        if (process != 0) {
            Flow.error.report("Error executing command: " + cmd);
        }
    }

    public static function systemName(): String {
        return Sys.systemName();
    }
}
