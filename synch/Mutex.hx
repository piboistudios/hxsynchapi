package synch;
using synch.Handle.HandleTools;
import synch.SynchLib;
class Mutex extends synch.Handle.NamedHandle {
    public static function create(name, initialOwner = false, global = false) {
        var handle:SynchronizationHandle = synch.SynchLib.mutex_create('${global ? 'Global' : 'Local'}\\$name', initialOwner);
        handle.checkErrors();
        return new Mutex('${global ? 'Global' : 'Local'}\\$name', handle);
    }
    public static function open(name, initialOwner = false, global = false) {
        var handle:SynchronizationHandle = synch.SynchLib.mutex_open('${global ? 'Global' : 'Local'}\\$name', initialOwner);
        handle.checkErrors();
        return new Mutex('${global ? 'Global' : 'Local'}\\$name', handle);
    }
    public function acquire(func:Void->Void, timeout = 10000) {
        this.wait(timeout);
        func();
        this.release();
    }
    public function release() {
        this.handle.mutex_release();
    }
}