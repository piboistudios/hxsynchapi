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

enum abstract MagicNumbers(Int) from Int to Int {
	/**
		You can improve performance significantly by choosing a small spin count for a critical section of short duration.
		For example, the heap manager uses a spin count of roughly 4,000 for its per-heap critical sections.
		See: https://docs.microsoft.com/en-us/windows/win32/api/synchapi/nf-synchapi-initializecriticalsectionandspincount
	**/
	var SPIN_COUNT = 4000;
}

@:asserts
class NativeTest {
	public function new() {}

	var handle:SynchronizationHandle;
	var eventId:String;
	var asserts = new AssertionBuffer();
    inline function printSlaveOutput(output)
        Sys.println('$liStart SLAVE OUTPUT:\r\n' + ~/($)/mg.replace(output, '$1$liStart\t\t'));
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
				Sys.sleep(1);
				trace('Signaling event@${Date.now()}');
				handle.event_signal();
			});
			handle.synch_wait_for_handle(10 * 1000);
<<<<<<< HEAD
		}, 1000, 10);
=======
		}, 5000, 1000);
>>>>>>> fa26e4e215c04cd8394dd63d0a44b14e5d79ea8d
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
				Sys.println('Sleeping 1 second');
			});
			Sys.sleep(1);
			// Sys.
		}, 2000, 100);
		#elseif master
		handle.event_reset();
		return Utils.shouldLast({
			// asserts = new AssertionBuffer();
			slave = new sys.io.Process('hl slave.sample.hl');
			slave.stdin.writeString('$eventId\r\n');
			
			Sys.println('Sent $eventId to slave, waiting 1 second');
			final initialOutput = slave.stdout.readUntil('%'.charCodeAt(0)).toString();
			printSlaveOutput(initialOutput);

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

	#if slave2
	public function test_open_mutex() {
		return assert(attempt({
			this.mutexId = Sys.stdin().readLine();
			this.mutex = synch.SynchLib.mutex_open('Global\\$mutexId', false);
			trace('my mutex: $mutex ($mutexId)');
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
    #if (master||slave2)
    public function test_ipc_mutex() {
        #if slave2
        trace('Waiting for handle%');
        mutex.synch_wait_for_handle(10 * 1000);
        final content = sys.io.File.getContent('./data.txt');
        sys.io.File.saveContent('./data.txt', content + content);
        mutex.mutex_release();
        return assert(sys.io.File.getContent('./data.txt') == 'some data\r\nsome data\r\n');
        #elseif master
        mutex.synch_wait_for_handle(10 * 1000);
        sys.io.File.saveContent('./data.txt', 'some data\r\n');
        final slave = new sys.io.Process('hl slave2.sample.hl');
        slave.stdin.writeString('$mutexId\r\n');
        slave.stdin.flush();
        printSlaveOutput(slave.stdout.readUntil('%'.charCodeAt(0)));
        trace('releasing mutex');
        mutex.mutex_release();
        mutex.synch_wait_for_handle(10 * 1000);
        asserts.assert(sys.io.File.getContent('./data.txt') == 'some data\r\nsome data\r\n');
        mutex.mutex_release();
        printSlaveOutput(slave.stdout.readAll().toString());
        asserts.assert(slave.exitCode(true) == 0);
        return asserts.done();
        #end
    }
    #end


	var criticalSection:CriticalSection;

	#if master
	public function test_init_critical_section() {
		return assert(attempt({
			criticalSection = synch.SynchLib.critical_section_init(SPIN_COUNT);
			trace('criticalSection: $criticalSection');
		}));
	}
	var criticalValue = 0;
	var done = 0;
	var numThreads = 50;
	function work_in_critical_section(ID:Int, a:AssertionBuffer) {
		sys.thread.Thread.create(() -> {
			inline function threadMsg(msg:String)
				trace('Thread ID $ID: $msg');

			// Sys.sleep(ID/5);
			// threadMsg("Attempting to enter critical section");
			criticalSection.critical_section_enter();
			// threadMsg("Entering crtiical section. Doing work.");
			Sys.sleep(Std.random(100)/500);
			criticalValue+= 10;
<<<<<<< HEAD
			Sys.sleep(0.1);
=======
>>>>>>> fa26e4e215c04cd8394dd63d0a44b14e5d79ea8d
			done++;
			a.assert(criticalValue == done * 10);
			// threadMsg("Leaving critical section. Work done. done: " + done);
			final isLastOut = done == numThreads;
			criticalSection.critical_section_leave();
<<<<<<< HEAD
			if (done == 10) {
				a.assert(criticalValue == 100);
				a.done();
=======
			if (isLastOut) {
				a.assert(criticalValue == numThreads * 10);
				a.done();	
>>>>>>> fa26e4e215c04cd8394dd63d0a44b14e5d79ea8d
			}
		});
	}
	@:timeout(30000)
	public function test_critical_section() {
		var a = new AssertionBuffer();
		for (i in 0...numThreads)
			work_in_critical_section(i, a);
		return a;
	}

	public function test_delete_critical_section() {
		return assert(attempt({
			criticalSection.critical_section_delete();
		}));
	}
<<<<<<< HEAD
    #end
    #if master
    var barrier:SynchronizationBarrier;
    public function test_create_barrier() {
        return assert(attempt({
            this.barrier = synch.SynchLib.synch_barrier_init(10, SPIN_COUNT);
        }));
    }
    public function test_synch_barrier() {
        var counter = 0;
        inline function dispatch(delay:Int)
            sys.thread.Thread.create(() -> {
                inline function msg(msg) trace('$liStart Thread $delay: $msg');
                msg('Waiting ${delay/10}s');
                Sys.sleep(delay/10);
         
                msg('Incrementing counter');
                counter++;
                msg('Entering barrier');
                barrier.synch_barrier_enter(false, false);
                msg('Passing barrier');
                if(delay == 0) asserts.assert(counter == 10);
                Sys.sleep(delay/10);
                msg('Decrementing counter');
                counter--;
                if(delay == 9) {
                    msg('Last out. Cleaning up');
                    barrier.synch_barrier_delete();
                    asserts.assert(counter == 0);
                    asserts.done();
                }
                
            });
        for(i in 0...10) {
            dispatch(i);
        }
        return asserts;

        
    }
    #end
=======
	#end
	#if master
	public function test_srw() {
		asserts = new AssertionBuffer();
		var lock:SrwLock = synch.SynchLib.srw_init_lock();
		final now = Date.now();
		sys.thread.Thread.create(() -> {
			lock.acquire_exclusive();
			final data = [];
			for(i in 0...Std.int(Std.random(50))) {
				data.push({
					name: 'test-$i',
					id: i,
					created: Date.now().getTime()
				});
			}
			final dataJson = haxe.Json.stringify(data, null, '\t');
			sys.io.File.saveContent('./srw-test.txt', dataJson);
			sys.io.File.saveContent('./srw-test.hash', haxe.crypto.Sha1.encode(dataJson));
			lock.release_exclusive();
		});
		sys.thread.Thread.create(() -> {
			Sys.sleep(0.1);
			lock.acquire_shared();
			final content = sys.io.File.getContent('./srw-test.txt');
			asserts.assert(sys.io.File.getContent('./srw-test.hash') == haxe.crypto.Sha1.encode(content));
			asserts.done();
			lock.release_shared();
		});
		return asserts;
	}
	#end
>>>>>>> fa26e4e215c04cd8394dd63d0a44b14e5d79ea8d
}
