package synch;

using synch.ErrorTools;

import synch.SynchLib;

class Handle {
	var handle:SynchronizationHandle;

	function new(h) {
		this.handle = h;
	}

	public function close() {
		this.handle.synch_close_handle();
	}

	function checkErrors() {
		HandleTools.checkErrors(this.handle);
	}

	public function wait(timeout:UInt) {
		HandleTools.wait(this, timeout);
	}

	public static function waitFirst(handles:Array<Handle>, timeout:UInt) {
		HandleTools.waitFirst(handles, timeout);
	}

	public static function waitAll(handles:Array<Handle>, timeout:UInt) {
		HandleTools.waitAll(handles, timeout);
	}
}

class NamedHandle extends Handle {
	public var name(default, null):String;

	public function new(name, h) {
		super(h);
		this.name = name;
	}
}

class HandleTools {
	public static function wait(handle:Handle, timeout:UInt) @:privateAccess {
		handle.handle.synch_wait_for_handle(timeout);
		handle.checkErrors();
	}

	static function waitMany(handles:Array<Handle>, timeout:UInt, waitAll = false) @:privateAccess {
		if (handles.length == 0)
			return;
		final masterHandle = handles[0];
		for (handle in handles.slice(1)) {
			synch.SynchLib.synch_gather_handle(masterHandle.handle, handle.handle);
		}
		masterHandle.handle.synch_wait_for_many(timeout, waitAll);
		masterHandle.checkErrors();
	}

	public static function waitFirst(handles:Array<Handle>, timeout:UInt) {
		waitMany(handles, timeout);
	}

	public static function waitAll(handles:Array<Handle>, timeout:UInt) {
		waitMany(handles, timeout);
	}

	public static function checkErrors(handle:synch.SynchronizationHandle) {
		if (handle.synch_errored()) {
            trace('SYNCH ERRORED: ${handle.synch_errored()}');
            throw handle.synch_get_errors().asErrorMsg();
        }
	}
}
