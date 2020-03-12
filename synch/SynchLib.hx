package synch;
import ammer.*;
import ammer.ffi.*;

// @:ammer.nativePrefix("sync")
class SynchLib extends Library<"synch"> {
  public static function event_create(name:String):SynchronizationHandle;
  public static function event_open(name:String):SynchronizationHandle;
  public static function critical_section_init(spinCount:UInt):CriticalSection;
  public static function synch_barrier_init(threads:UInt, spinCount:UInt):SynchronizationBarrier;
  public static function mutex_create(name:String, initialOwner:Bool):SynchronizationHandle;
  public static function mutex_open(name:String, initialOwner:Bool):SynchronizationHandle;
  public static function synch_gather_handle(a:SynchronizationHandle, b:SynchronizationHandle):Void;
  public static function srw_init_lock():SrwLock;
}
class SynchronizationHandle extends Pointer<"synch_handle_t", SynchLib> {
  
  public function synch_wait_for_handle(_:This, duration:UInt):Void;
  public function synch_wait_for_many(_:This, duration:UInt, waitAll:Bool):Void;
  public function mutex_release(_:This):Void;
  public function event_signal(_:This):Void;
  public function event_reset(_:This):Void;
}
// @:ammer.nativePrefix("critical_section_")
class CriticalSection extends Pointer<"critical_section_t", SynchLib> {
  public function critical_section_enter(_:This):Void;
  public function critical_section_leave(_:This):Void;
  public function critical_section_delete(_:This):Void;
}
// @:ammer.nativePrefix("synch_barrier_")
class SynchronizationBarrier extends Pointer<"barrier_t", SynchLib> {
  public function synch_barrier_enter(_:This, spinOnly:Bool, blockOnly:Bool):Void;
  public function synch_barrier_delete(_:This):Void;
}
@:ammer.nativePrefix("srw_")
class SrwLock extends Pointer<"srw_lock_t", SynchLib> {
  public function try_acquire_exclusive(_:This):Bool;
  public function try_acquire_shared(_:This):Bool;
  public function release_exclusive(_:This):Void;
  public function release_shared(_:This):Void;
  public function acquire_exclusive(_:This):Void;
  public function acquire_shared(_:This):Void;
}
