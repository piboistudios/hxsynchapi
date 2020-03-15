package synch;
using synch.ErrorTools;
class SrwLock {
    var lock:synch.NativeSrwLock;
    function new(lock) {
        this.lock = lock;
    }
    public static function create() {
        final lock = synch.SynchLib.srw_init_lock();
        if(lock.errored()) throw lock.get_errors().asErrorMsg();
        return new SrwLock(lock);
    }
    function doTryAcquire(exclusive) {
        return if(exclusive) this.lock.try_acquire_exclusive(); else this.lock.try_acquire_shared();
    }
    function doAcquire(exclusive) {
        return if(exclusive) this.lock.acquire_exclusive(); else this.lock.acquire_shared();
    }
    function doRelease(exclusive) {
        return if(exclusive) this.lock.release_exclusive(); else this.lock.release_shared();
    }
    public function acquire(onceAcquired:Void->Void, exclusive = false) {
        doAcquire(exclusive);
        onceAcquired();
        doRelease(exclusive);
    }
}