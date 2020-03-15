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

	var criticalSection:synch.CriticalSection<{asserts:tink.unit.AssertionBuffer, data:String, accessCount:Int}>;
	var asserts = new AssertionBuffer();

	public function testCriticalSectionCreation() {
		return assert(attempt({
			criticalSection = CriticalSection.create({accessCount: 0, asserts: asserts, data: "initial state"});
		}));
	}

	var numThreads = 20;

	@:timeout(30000)
	public function testCriticalSection() {
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
						asserts.assert(state.data == 'changed ${numThreads}x');
						asserts.done();
					}
				});
			});
		}
		return asserts;
	}

	var barrier:synch.SynchBarrier;

	public function testSynchBarrierCreation() {
		return assert(attempt({
			asserts = new AssertionBuffer();
			barrier = synch.SynchBarrier.create(numThreads, 8000);
			criticalSection.close();
			criticalSection = CriticalSection.create({accessCount: 0, asserts: asserts, data: "initial state"});
		}));
	}

	public function testSynchBarrier() {
		var counter = 0;
		for (i in 0...numThreads)
			sys.thread.Thread.create(() -> {
				barrier.enter(last -> {
					criticalSection.enter(state -> {
						state.accessCount++;
						counter++;
						if(last) {
							trace('LAST: ${state.accessCount}');
						}
						if (state.accessCount == numThreads) {
							state.asserts.assert(counter == state.accessCount);
							state.asserts.done();
						}
					});
				});
			});
		criticalSection.enter(state -> {
			asserts = state.asserts;
		});
		return asserts;
	}
	#end
}
