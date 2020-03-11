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
#include <synchapi.h>
#include <tchar.h>
    typedef struct {
		char** errors;
		char* error_str;
		int num_errors;
        bool has_errors;
	} synch_errors_t, *synch_errors_p;
    typedef struct {
        synch_errors_p errors;
        HANDLE handle;
    } synch_handle_t, *synch_handle_p;
    // typedef synch_errors_t* synch_errors_p;
LIB_EXPORT synch_handle_p create_event(char* name);
LIB_EXPORT void signal_event(synch_handle_p handle);
LIB_EXPORT void reset_event(synch_handle_p handle);
LIB_EXPORT synch_handle_p open_event(char* name);
#ifdef __cplusplus
}
#endif
