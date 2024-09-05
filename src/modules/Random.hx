package modules;

class Random {
    public static function nextInt(min:Int, max:Int):Int {
        return min + Std.random(max - min + 1);
    }

    public static function choice<T>(list:Array<T>):T {
        if (list.length == 0) {
            Flow.error.report("Cannot choose from an empty list.");
        }
        var index:Int = nextInt(0, list.length - 1);
        return list[index];
    }

    public static function weightedChoice<T>(list:Array<T>, weights:Array<Float>):T {
        if (list.length != weights.length) {
            Flow.error.report("List and weights must have the same length.");
        }

        var totalWeight:Float = 0;
        for (weight in weights) {
            totalWeight += weight;
        }

        var rand:Float = Math.random() * totalWeight;
        var cumulativeWeight:Float = 0;

        for (i in 0...list.length) {
            cumulativeWeight += weights[i];
            if (rand < cumulativeWeight) {
                return list[i];
            }
        }

        return list[list.length - 1];
    }

    public static function shuffle<T>(list:Array<T>):Array<T> {
        var shuffled:Array<T> = list.copy();
        for (i in 0...shuffled.length) {
            var j:Int = nextInt(0, i);
            var temp:T = shuffled[i];
            shuffled[i] = shuffled[j];
            shuffled[j] = temp;
        }
        return shuffled;
    }

    public static function sample<T>(list:Array<T>, n:Int):Array<T> {
        if (n > list.length) {
            Flow.error.report("Sample size cannot be larger than the list size.");
        }
        var copy:Array<T> = shuffle(list);
        return copy.slice(0, n);
    }

    public static function gaussian(mean:Float, stddev:Float):Float {
        var u1:Float = Math.random();
        var u2:Float = Math.random();
        var z0:Float = Math.sqrt(-2.0 * std.Math.log(u1)) * Math.cos(2.0 * Math.getPI() * u2);
        return z0 * stddev + mean;
    }
}
