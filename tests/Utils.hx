import haxe.macro.Expr;
import tink.testrunner.*;
import tink.unit.*;
import tink.unit.Assert.assert;
class Utils {
    public static macro function  attempt(expr:Expr){

        return macro try {
            $expr;
            true;
        } catch(e:Any) {
            trace(e);
            false;
        };
    
    }
    public static macro function shouldLast(expr:Expr, expected:ExprOf<Int>, threshhold:ExprOf<Int>, ?asserts:ExprOf<tink.unit.AssertionBuffer>){
        return macro {
            final then = Date.now();
            trace('Start:' + then);
            $expr;
            final now = Date.now();
            final delta = (now.getTime() - then.getTime());
            trace('Delta/Expected: ' +  Std.string(delta) + "/" + $expected);
            trace('End:' +  now);
            var _a = $asserts;
            if(_a == null)
                _a = new AssertionBuffer();
            _a.assert(delta > $expected - $threshhold && delta < $expected + $threshhold);
            _a.done();
            return _a;
        };
    }
}