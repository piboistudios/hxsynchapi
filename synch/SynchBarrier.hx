package synch;
import synch.SynchLib;
using synch.ErrorTools;

class SynchBarrier {
	var barrier:SynchronizationBarrier;
	public var capacity(default, null):Int;
	function new(barrier, capacity) {
		this.barrier = barrier;
		this.capacity = capacity;
	}

	public static function check(barrier:SynchronizationBarrier) {
		if (barrier.synch_barrier_errored())
			throw barrier.synch_barrier_get_errors().asErrorMsg();
	}

	public function checkErrors() {
		check(this.barrier);
	}
	
	public static function create(capacity = 1, spinCount = 4000) {
		final barrier = synch.SynchLib.synch_barrier_init(capacity, spinCount);
		SynchBarrier.check(barrier);
		return new SynchBarrier(barrier, capacity);
	}

	function doEnter(spinOnly = false, blockOnly = false) {
		final ret = this.barrier.synch_barrier_enter(spinOnly, blockOnly);
		return ret;
	}

	public function enter(func:Null<Bool->Void> = null, spin = true, block = false) {
		final ret = doEnter(spin, block);
		if (func != null)
			func(ret);
		return ret;
	}

	public function close() {
		this.barrier.synch_barrier_delete();
	}
}
