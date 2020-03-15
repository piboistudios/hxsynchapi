package synch;

import synch.SynchLib;

using synch.ErrorTools;

class CriticalSection<T> {
	var state:T;
	var section:NativeCriticalSection;
	var closed:Bool;

	public var queued(default, null):Int;
	public var occupied(default, null):Bool;

	function new(section, state) {
		this.section = section;
		this.state = state;
	}

	static function checkErrors(section:synch.NativeCriticalSection) {
		if (section.critical_section_errored())
			throw section.critical_section_get_errors().asErrorMsg();
	}

	public static function create<T>(initialState, spinCount = 4000) {
		final section = synch.SynchLib.critical_section_init(spinCount);
		CriticalSection.checkErrors(section);
		return new CriticalSection(section, initialState);
	}

	public function enter(run:T->Void, ?alreadyEntered:Bool) {
		// trace('entering');
		if (!alreadyEntered) {
			this.queued++;
			this.section.critical_section_enter();
			this.occupied = true;
		}
		run(this.state);
		this.occupied = false;
		this.queued--;
		this.section.critical_section_leave();
		// trace('leaving $queued');
	}

	public function tryEnter(run:T->Void):Bool {
		final ret = this.section.critical_section_try_enter();
		if (ret) {
			this.occupied = true;
			this.queued++;
			this.enter(run, true);
		}
		return ret;
	}

	public function close() {
		if (this.closed)
			return;
		this.closed = true;
		this.section.critical_section_delete();
	}
}
