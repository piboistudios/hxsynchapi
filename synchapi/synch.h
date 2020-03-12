//#pragma once
#ifdef __cplusplus
extern "C" {
#endif

#ifdef _WIN32
#define LIB_EXPORT __declspec(dllexport)
#else
#define LIB_EXPORT
#endif
#define WIN32_LEAN_AND_MEAN      // Exclude rarely-used stuff from Windows headers

#include <windows.h>
#include <stdbool.h>
#include <aclapi.h>
#include <stdio.h>
#include <synchapi.h>
#include <tchar.h>
    typedef struct {
		char** errors;
		char* error_str;
		int num_errors;
        bool has_errors;
	} synch_errors_t, *synch_errors_p;
    typedef struct {
        synch_errors_p reporter;
        HANDLE handle;
        HANDLE *gathered;
        bool gather_started;
        int gather_count;
        int capacity;
        DWORD wait_status;
    } synch_handle_t, *synch_handle_p;
    typedef struct {
        synch_errors_p reporter;
        LPCRITICAL_SECTION critical_section;
        DWORD spin_count;
    } critical_section_t, *critical_section_p;
    typedef struct {
        synch_errors_p reporter;
        LPSYNCHRONIZATION_BARRIER barrier;
        DWORD threads;
        DWORD spin_count;
    } barrier_t,*barrier_p;
    typedef struct {
        synch_errors_p reporter;
        PSRWLOCK lock;
    } srw_lock_t, *srw_lock_p;
    // typedef synch_errors_t* synch_errors_p;
LIB_EXPORT synch_handle_p event_create(char* name);
LIB_EXPORT void event_signal(synch_handle_p handle);
LIB_EXPORT void event_reset(synch_handle_p handle);
LIB_EXPORT synch_handle_p event_open(char* name);
LIB_EXPORT void synch_wait_for_handle(synch_handle_p handle, DWORD duration);
LIB_EXPORT void synch_gather_handle(synch_handle_p s, synch_handle_p t);
LIB_EXPORT void synch_wait_for_many(synch_handle_p s, DWORD duration, bool wait_all);
LIB_EXPORT critical_section_p critical_section_init(DWORD spin_count);
LIB_EXPORT void critical_section_enter(critical_section_p ctx);
LIB_EXPORT void critical_section_leave(critical_section_p ctx);
LIB_EXPORT void critical_section_delete(critical_section_p ctx);
LIB_EXPORT barrier_p  synch_barrier_init(DWORD threads, DWORD spin_count);
LIB_EXPORT void synch_barrier_enter(barrier_p barrier, bool spin_only, bool block_only) ;
LIB_EXPORT void synch_barrier_delete(barrier_p barrier);
LIB_EXPORT synch_handle_p mutex_create(const char* name, bool initial_owner);
LIB_EXPORT synch_handle_p mutex_open(const char* name, bool initial_owner);
LIB_EXPORT void mutex_release(synch_handle_p mutex);
LIB_EXPORT srw_lock_p srw_init_lock();
LIB_EXPORT bool srw_try_acquire_exclusive(srw_lock_p srw);
LIB_EXPORT bool srw_try_acquire_shared(srw_lock_p srw);
LIB_EXPORT void srw_release_exclusive(srw_lock_p srw) ;
LIB_EXPORT void srw_release_shared(srw_lock_p srw) ;
LIB_EXPORT void srw_acquire_exclusive(srw_lock_p srw) ;
LIB_EXPORT void srw_acquire_shared(srw_lock_p srw) ;
#ifdef __cplusplus
}
#endif
