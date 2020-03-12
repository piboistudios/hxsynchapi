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
    #if (master || slave)
	public function test_create_event() {
		return assert(attempt({
			#if master
			eventId = Std.string(Std.random(10000));
			handle = synch.SynchLib.event_create("Local\\" + eventId);
			trace('Created event ID $eventId');
			#elseif slave
			eventId = Sys.stdin().readLine();
			handle = synch.SynchLib.event_open("Local\\" + eventId);
			trace('Opened existing event ID $eventId');
			#end
		}));
    }
    #end

	#if master
	public function event_wait_handle() {
		return Utils.shouldLast({
			Thread.create(() -> {
				Sys.sleep(5);
				trace('Signaling event@${Date.now()}');
				handle.event_signal();
			});
			handle.synch_wait_for_handle(10 * 1000);
		}, 5000, 10);
	}
	#end

	var liStart = '>>>>>>>>';
	#if (master || slave)
	var slave:sys.io.Process;

	public function test_ipc_event() {
		#if slave
		return Utils.shouldLast({
			Sys.println('Waiting for event to trigger');
			Sys.println('%');
			handle.synch_wait_for_handle(10 * 1000);
			sys.thread.Thread.create(() -> {
				Sys.println('Event triggered');
				Sys.println('Closing slave');
				Sys.println('Sleeping 1 seconds');
			});
			Sys.sleep(1);
			// Sys.
		}, 2000, 1000);
		#elseif master
		handle.event_reset();
		return Utils.shouldLast({
			slave = new sys.io.Process('hl slave.sample.hl');
			slave.stdin.writeString('$eventId\r\n');
			inline function printSlaveOutput(output)
				Sys.println('$liStart SLAVE OUTPUT:\r\n' + ~/($)/mg.replace(output, '$1$liStart\t\t'));
			sys.thread.Thread.create(() -> {
				Sys.println('Sent $eventId to slave, waiting 1 seconds');
				final initialOutput = slave.stdout.readUntil('%'.charCodeAt(0)).toString();
				printSlaveOutput(initialOutput);
			});
			Sys.sleep(1);
			Sys.println('Signaling event');
			handle.event_signal();
			final finalOutput = slave.stdout.readAll().toString();
			printSlaveOutput(finalOutput);
			final exitCode = slave.exitCode(true);
			asserts.assert(finalOutput.indexOf('Closing slave') != -1);
			asserts.assert(finalOutput.indexOf('0 Failure') != -1);
			asserts.assert(exitCode == 0);
		}, 2000, 1000, asserts);
		#end
	}
    #end
    var mutex:SynchronizationHandle;
    var mutexId:String;
    #if master
    public function test_create_mutex() {
        return assert(attempt({
            this.mutexId = Std.string(Std.random(10000));
            this.mutex = synch.SynchLib.mutex_create('Global\\$mutexId', false);
        }));
    }
    #end
    #if master
    public function mutex_wait_handle() {
        return Utils.shouldLast({
            Thread.create(() -> {
                mutex.synch_wait_for_handle(10 * 1000);
                trace('$liStart Thread - Acquired handle; releasing in 1 second');
                Sys.sleep(1);
                trace('$liStart Thread - releasing handle');
                mutex.mutex_release();
            });
            Sys.sleep(0.1);
            trace('Process - Waiting for handle.');
            mutex.synch_wait_for_handle(10 * 1000);
            trace('Process - Acquired handle; releasing in 1 second');
            Sys.sleep(1);
            trace('Process - releasing handle');
            mutex.mutex_release();
        }, 2000, 1000);
    }
    #end
}
