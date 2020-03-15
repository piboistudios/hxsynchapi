package synch;
using synch.SynchLib;
using synch.ErrorTools;
using synch.Handle.HandleTools;
import synch.SynchLib;
class Event extends synch.Handle.NamedHandle {
    public function signal(reset = false) {
        doSignal();
        if(reset) doReset();
    }
    public function reset() {
        
        doReset();
    }
    function doSignal() {
        if(closed) return;
        this.handle.event_signal();
        checkErrors();
    }
    function doReset() {
        if(closed) return;
        this.handle.event_reset();
        checkErrors();
    }
    public static function create(name, global = false) @:privateAccess {
        final handle:SynchronizationHandle = synch.SynchLib.event_create('${global ? 'Global' : 'Local'}\\$name');
        handle.checkErrors();
        return new Event('${global ? 'Global' : 'Local'}\\$name', handle);
    }
    public static function open(name, global = false) @:privateAccess {
        final handle:SynchronizationHandle = synch.SynchLib.event_open('${global ? 'Global' : 'Local'}\\$name');
        handle.checkErrors();
        return new Event('${global ? 'Global' : 'Local'}\\$name', handle);
    }
}
