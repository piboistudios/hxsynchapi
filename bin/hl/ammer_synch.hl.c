#define HL_NAME(n) ammer_synch_ ## n
#include <hl.h>
#include <synch.h>
HL_PRIM synch_handle_t * HL_NAME(w_create_event)(char * arg_0) {
  return create_event(arg_0);
}
DEFINE_PRIM(_ABSTRACT(synch_handle_t), w_create_event, _BYTES);
HL_PRIM synch_handle_t * HL_NAME(w_open_event)(char * arg_0) {
  return open_event(arg_0);
}
DEFINE_PRIM(_ABSTRACT(synch_handle_t), w_open_event, _BYTES);
HL_PRIM void HL_NAME(w_gather_handle)(synch_handle_t * arg_0, synch_handle_t * arg_1) {
  gather_handle(arg_0, arg_1);
}
DEFINE_PRIM(_VOID, w_gather_handle, _ABSTRACT(synch_handle_t) _ABSTRACT(synch_handle_t));
HL_PRIM void HL_NAME(w_signal_event)(synch_handle_t * arg_0) {
  signal_event(arg_0);
}
DEFINE_PRIM(_VOID, w_signal_event, _ABSTRACT(synch_handle_t));
HL_PRIM void HL_NAME(w_reset_event)(synch_handle_t * arg_0) {
  reset_event(arg_0);
}
DEFINE_PRIM(_VOID, w_reset_event, _ABSTRACT(synch_handle_t));
HL_PRIM void HL_NAME(w_wait_for_handle)(synch_handle_t * arg_0, int arg_1) {
  wait_for_handle(arg_0, arg_1);
}
DEFINE_PRIM(_VOID, w_wait_for_handle, _ABSTRACT(synch_handle_t) _I32);
HL_PRIM void HL_NAME(w_wait_for_many)(synch_handle_t * arg_0, int arg_1, bool arg_2) {
  wait_for_many(arg_0, arg_1, arg_2);
}
DEFINE_PRIM(_VOID, w_wait_for_many, _ABSTRACT(synch_handle_t) _I32 _BOOL);
