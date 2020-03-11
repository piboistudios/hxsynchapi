package synch;
import ammer.*;
import ammer.ffi.*;

// @:ammer.nativePrefix("sync")
class SynchLib extends Library<"synch"> {
  public static function create_event(name:String):SynchronizationHandle;
  public static function open_event(name:String):SynchronizationHandle;
  public static function gather_handle(a:SynchronizationHandle, b:SynchronizationHandle):Void;
}
// @:ammer.nativePrefix("odbc_")
class SynchronizationHandle extends Pointer<"synch_handle_t", SynchLib> {
  public function signal_event(_:This):Void;
  public function reset_event(_:This):Void;
  public function wait_for_handle(_:This, duration:Int):Void;
  public function wait_for_many(_:This, duration:Int, waitAll:Bool):Void;
}
