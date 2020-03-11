package;
import sys.thread.*;
import tink.testrunner.*;
import tink.unit.*;
import tink.unit.Assert.assert;
import synch.SynchLib;
import sys.FileSystem;
import Utils.attempt;

using tink.CoreApi;
using Lambda;

class RunTests {
	static function main() {
		Runner.run(TestBatch.make([new BasicTest()])).handle(Runner.exit);
	}
}


class BasicTest {
    public function new() {}
    var handle:SynchronizationHandle;
    public function test_create_event() {
        handle = synch.SynchLib.create_event("Local\\" + Std.string(Std.random(10000)));
        return assert(handle != null);
    }
    public function wait_handle() {
        final now = Date.now();
        trace('Start: $now');
        Thread.create(() -> {
            Sys.sleep(5);
            trace('Signaling event@${Date.now()}');
            handle.signal_event();
        });
        handle.wait_for_handle(10 * 1000);
        final then = Date.now();
        final delta = (then.getTime() - now.getTime());
        final expected = 5000;
        final threshhold = 10;
        trace('Delta/Expected: $delta/$expected');
        trace('End: $then');
        return assert(delta > expected - threshhold && delta < expected + threshhold);
    }
}