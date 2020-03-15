# HxSynchAPI

HxSynchAPI is a HashLink port of several [Windows Synchronization APIs](https://docs.microsoft.com/en-us/windows/win32/sync/about-synchronization).

It is a WIP.

TODO:
- [x] - Create Haxe Native FFI Proxy
- [x] - Events
- [x] - Mutexes (needs working test.. need some shared I/O/IPC message passing)
- [x] - Critical Sections (needs try access)
- [x] - SRW Locks
- [x] - Synchronization Barriers (needs test)
- [ ] - Maybe Interlocked Variables?
- [ ] - Maybe Interlocked SLists?
- [x] - Expose User Friendly Haxe API
- [x] - Build automation
- [ ] - Add usage examples

## Events

```haxe
final FOREVER = -1;
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
        task.wait(FOREVER);
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
    ready.wait(FOREVER);
    task.reset();
}
inline function kill() {
    kill = true;
}
queueTask(() -> {
    trace('foo');
});
```