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
            trace('ERROR:' +e);
            trace(haxe.CallStack.toString(haxe.CallStack.exceptionStack()));
            false;
        };
    
    }
    public static macro function shouldLast(expr:Expr, expected:ExprOf<Int>, threshhold:ExprOf<Int>, ?asserts:ExprOf<tink.unit.AssertionBuffer>, ?done:ExprOf<Dynamic>){
        return macro {
            var _a = $asserts;
            var _d:Dynamic = $done;
            if(_a == null) _a = new tink.unit.AssertionBuffer();
            final then = Date.now();
            trace('Start:' + then);
            $expr;
            final now = Date.now();
            final delta = (now.getTime() - then.getTime());
            trace('Delta/Expected: ' +  Std.string(delta) + "/" + $expected);
            trace('End:' +  now);
            
            _a.assert(delta >= $expected - $threshhold && delta <= $expected + $threshhold);
            if(_d != false) _a.done();
            
            return _a;
        };
    }
}