package;
import sys.thread.*;
import tink.testrunner.*;
import tink.unit.*;
import tink.unit.Assert.assert;
import synch.SynchLib;
import sys.FileSystem;
import Utils.attempt;
using Utils;

using tink.CoreApi;
using Lambda;

class RunTests {
	static function main() {
		Runner.run(TestBatch.make([new NativeTest()])).handle(Runner.exit);
	}
}


class NativeTest {
    public function new() {}
    var handle:SynchronizationHandle;
    var eventId:String;
    var asserts = new AssertionBuffer();
    public function test_create_event() {
        return assert(attempt({
            #if master
            eventId = Std.string(Std.random(10000));
            handle = synch.SynchLib.create_event("Local\\" + eventId);
            #elseif slave
            eventId = Sys.stdin().readLine();
            handle = synch.SynchLib.open_event("Local\\" + eventId);
            #end
        }));
    }
    #if master
    public function wait_handle() {
        return Utils.shouldLast({
            Thread.create(() -> {
                Sys.sleep(5);
                trace('Signaling event@${Date.now()}');
                handle.signal_event();
            });
            handle.wait_for_handle(10 * 1000);
        }, 5000, 10);
    }
    #end
    var slave:sys.io.Process;
    var liStart = '>>>>>>>>';
    public function test_ipc_event() {
        #if slave
        return Utils.shouldLast({
            handle.wait_for_handle(10 * 1000);
            Sys.println('Closing slave');
            Sys.sleep(2.5);
            // Sys.
        }, 5000, 10);
        #elseif master
        handle.reset_event();
        return Utils.shouldLast({
            slave = new sys.io.Process('hl slave.sample.hl');
            slave.stdin.writeString('$eventId\r\n');
            Sys.sleep(2.5);
            handle.signal_event();
            final output = slave.stdout.readAll().toString();
            Sys.println('$liStart SLAVE OUTPUT:\r\n' + ~/($)/mg.replace(output, '$1$liStart\t\t'));
            final exitCode = slave.exitCode(true);
            asserts.assert(output.indexOf('Closing slave') != -1);
            asserts.assert(output.indexOf('0 Failure') != -1);
            asserts.assert(exitCode == 0);
        }, 5000, 25, asserts);
        #else
            #error
        #end
    }
}