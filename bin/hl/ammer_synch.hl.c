#define HL_NAME(n) ammer_synch_ ## n
#include <hl.h>
#include <synch.h>
HL_PRIM synch_handle_t * HL_NAME(w_event_create)(char * arg_0) {
  return event_create(arg_0);
}
DEFINE_PRIM(_ABSTRACT(synch_handle_t), w_event_create, _BYTES);
HL_PRIM synch_handle_t * HL_NAME(w_event_open)(char * arg_0) {
  return event_open(arg_0);
}
DEFINE_PRIM(_ABSTRACT(synch_handle_t), w_event_open, _BYTES);
HL_PRIM void HL_NAME(w_synch_gather_handle)(synch_handle_t * arg_0, synch_handle_t * arg_1) {
  synch_gather_handle(arg_0, arg_1);
}
DEFINE_PRIM(_VOID, w_synch_gather_handle, _ABSTRACT(synch_handle_t) _ABSTRACT(synch_handle_t));
HL_PRIM void HL_NAME(w_event_signal)(synch_handle_t * arg_0) {
  event_signal(arg_0);
}
DEFINE_PRIM(_VOID, w_event_signal, _ABSTRACT(synch_handle_t));
HL_PRIM void HL_NAME(w_event_reset)(synch_handle_t * arg_0) {
  event_reset(arg_0);
}
DEFINE_PRIM(_VOID, w_event_reset, _ABSTRACT(synch_handle_t));
HL_PRIM void HL_NAME(w_synch_wait_for_handle)(synch_handle_t * arg_0, int arg_1) {
  synch_wait_for_handle(arg_0, arg_1);
}
DEFINE_PRIM(_VOID, w_synch_wait_for_handle, _ABSTRACT(synch_handle_t) _I32);
HL_PRIM void HL_NAME(w_synch_wait_for_many)(synch_handle_t * arg_0, int arg_1, bool arg_2) {
  synch_wait_for_many(arg_0, arg_1, arg_2);
}
DEFINE_PRIM(_VOID, w_synch_wait_for_many, _ABSTRACT(synch_handle_t) _I32 _BOOL);
