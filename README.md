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

## Events

```haxe
final FOREVER = -1;
var event = synch.SynchLib.create('my-event');
var then = function() {};
sys.thread.Thread.create(() -> {
    function beginWork() {
        // do some work here
    }
    while(event.wait(FOREVER)) {
        beginWork();
        then();
    }
});
inline function runBackgroundTask(_then:Void->Void) {
    then = _then;
    event.signal(true);
}
```