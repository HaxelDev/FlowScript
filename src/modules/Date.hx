package modules;

using StringTools;

class DateTools {
    public static function getCurrentDateTime():String {
        return Date.now().toString();
    }

    public static function getCurrentDate():String {
        var now = Date.now();
        return Std.string(now.getFullYear()) + "-" 
            + StringTools.lpad(Std.string(now.getMonth() + 1), "0", 2) + "-" 
            + StringTools.lpad(Std.string(now.getDate()), "0", 2);
    }

    public static function getCurrentTime():String {
        var now = Date.now();
        return StringTools.lpad(Std.string(now.getHours()), "0", 2) + ":" 
            + StringTools.lpad(Std.string(now.getMinutes()), "0", 2) + ":" 
            + StringTools.lpad(Std.string(now.getSeconds()), "0", 2);
    }

    public static function formatDate(date:Date):String {
        return Std.string(date.getFullYear()) + "-" 
            + StringTools.lpad(Std.string(date.getMonth() + 1), "0", 2) + "-" 
            + StringTools.lpad(Std.string(date.getDate()), "0", 2);
    }

    public static function formatTime(date:Date):String {
        return StringTools.lpad(Std.string(date.getHours()), "0", 2) + ":" 
            + StringTools.lpad(Std.string(date.getMinutes()), "0", 2) + ":" 
            + StringTools.lpad(Std.string(date.getSeconds()), "0", 2);
    }

    public static function fromString(dateString:String):Date {
        var parts = dateString.split(" ");
        if (parts.length == 2) {
            var dateParts = parts[0].split("-");
            var timeParts = parts[1].split(":");
            if (dateParts.length == 3 && timeParts.length == 3) {
                var year = Std.parseInt(dateParts[0]);
                var month = Std.parseInt(dateParts[1]) - 1;
                var day = Std.parseInt(dateParts[2]);
                var hours = Std.parseInt(timeParts[0]);
                var minutes = Std.parseInt(timeParts[1]);
                var seconds = Std.parseInt(timeParts[2]);
                return new Date(year, month, day, hours, minutes, seconds);
            }
        }
        Flow.error.report("Invalid date format: " + dateString);
        return null;
    }

    public static function diffInSeconds(date1:Date, date2:Date):Float {
        return (date2.getTime() - date1.getTime()) / 1000;
    }
}
