package;

import sys.thread.*;
import tink.testrunner.*;
import tink.unit.*;
import tink.unit.Assert.assert;
import synch.SynchLib;
import sys.FileSystem;
import Utils.attempt;
import synch.*;

using Utils;
using tink.CoreApi;
using Lambda;

class RunTests {
	static function main() {
		// final tests:Array<BasicTest> = [];
		Runner.run(TestBatch.make([
			new BasicTest()
			// new BasicTest(),
			// new BasicTest(),
			// new BasicTest(),
			// new BasicTest(),
			// new BasicTest(),
			// new BasicTest(),
			// new BasicTest(),
			// new BasicTest(),
			// new BasicTest(),
			// new BasicTest()
		])).handle(Runner.exit);
	}
}

@:asserts
class BasicTest {
	public function new() {}

	#if master
	var event:Event;
	var eventId:String;

	// public function testLoopBogDown() {
	// 	var i = 10 * 1000 * 100;
	// 	while(i-- != 0) {
	// 		Sys.sleep(0.1);
	// 	}
	// 	trace('Wait over');
	// 	return assert(true);
	// }

	@:teardown
	public function teardown() {
		event.close();
		criticalSection.close();
		barrier.close();
		mutex.close();
		return Noise;
	}

	public function createEvent() {
		return assert(attempt({
			eventId = Std.string(Std.random(1000000));
			event = Event.create(eventId);
		}));
	}

	public function confirmName() {
		return assert(event.name == 'Local\\$eventId');
	}

	public function testWait() {
		return Utils.shouldLast({
			Thread.create(() -> {
				Sys.sleep(1);
				trace('Signaling event@${Date.now()}');
				event.signal();
			});
			event.wait(10 * 1000);
		}, 1000, 1000);
	}
	public function testBackgroundTask() {
		var counter = 0;
		final callbacks:Array<Void->Void> = [];
		var task = Event.create('task$eventId');
		var ready = Event.create('ready$eventId');
		var kill = false;
		sys.thread.Thread.create(() -> {
			inline function backgroundJob() {
				trace('running background job');
			}
			while(!kill) {
				ready.signal();
				task.wait(-1);
				ready.reset();
				backgroundJob();
				if(callbacks.length != 0) callbacks.shift()();
			}
			ready.close();
			task.close();
		});
		inline function queueTask(t:Void->Void) {
			callbacks.push(t);
			task.signal();
			ready.wait(-1);
			task.reset();
		}
		for(i in 0...10) 
			queueTask(() -> {
				counter++;
				asserts.assert(counter == i + 1);
			});
		queueTask(() -> {
			asserts.done();
			kill = true;
		});
		return asserts;
	}
	var mutex:synch.Mutex;	
	var mutexId:String;

	public function createMutex() {
		return assert(attempt({

			mutexId = Std.string(Std.random(1000000));
			mutex = Mutex.create(mutexId);
		}));
	}
	public function testWaitMutex() {
		return Utils.shouldLast({
			Thread.create(() -> {
				mutex.acquire(() -> {
					Sys.sleep(1);
				});
			});
			Sys.sleep(0.5);
			mutex.acquire(() -> {
			});
		}, 1000, 1000);
	}

	var criticalSection:synch.CriticalSection<{data:String, accessCount:Int}>;
	var asserts:AssertionBuffer;
	@:setup
	public function setup() {
		asserts = new AssertionBuffer();
		return Noise;
	}
	public function testCriticalSectionCreation() {
		return assert(attempt({
			criticalSection = CriticalSection.create({accessCount: 0, data: "initial state"});
		}));
	}

	var numThreads = 10;
	@:exclude
	@:timeout(30000)
	public function testCriticalSection() {
		var done = Event.create('done$eventId');
		var data = '';
		for (i in 0...numThreads) {
			// Sys.sleep((i + 1)/1000);
			final _i = i;
			sys.thread.Thread.create(() -> {
				criticalSection.enter(state -> {
					if (state.accessCount == 0) {
						asserts.assert(state.data == 'initial state');
					}
					state.accessCount++;
					state.data = 'changed ${state.accessCount}x';
					if (state.accessCount == numThreads) {
						data = state.data;	
						done.signal();
					}
				});
			});
		}
		done.wait(-1);
		done.close();
		asserts.assert(data == 'changed ${numThreads}x');
		return asserts.done();
	}

	var barrier:synch.SynchBarrier;

	public function testSynchBarrierCreation() {
		return assert(attempt({
			barrier = synch.SynchBarrier.create(numThreads, 4000);
		}));
	}

	public function testSynchBarrier() {
		var reachedBarrier = Event.create('barrier$eventId');
		var counter = 0;
		for (i in 0...numThreads)
			sys.thread.Thread.create(() -> {

				barrier.enter(last -> {
					reachedBarrier.signal();
				});
			});
		reachedBarrier.wait(-1);
		barrier.close();
		asserts.assert(true, 'barrier reached');
		reachedBarrier.close();
		return asserts.done();
	}
	#end
}
