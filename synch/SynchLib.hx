package synch;
import ammer.*;
import ammer.ffi.*;

// @:ammer.nativePrefix("sync")
class SynchLib extends Library<"synch"> {
  public static function event_create(name:String):SynchronizationHandle;
  public static function event_open(name:String):SynchronizationHandle;
  public static function synch_gather_handle(a:SynchronizationHandle, b:SynchronizationHandle):Void;
}
// @:ammer.nativePrefix("odbc_")
class SynchronizationHandle extends Pointer<"synch_handle_t", SynchLib> {
  public function event_signal(_:This):Void;
  public function event_reset(_:This):Void;
  public function synch_wait_for_handle(_:This, duration:Int):Void;
  public function synch_wait_for_many(_:This, duration:Int, waitAll:Bool):Void;
}
