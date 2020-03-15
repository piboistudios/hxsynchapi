#include "synch.h"

/*
* Errors
*/


char* print_errors(synch_errors_p errors) {
    // errors->error_str = (char*)malloc(sizeof(char) * 2048);
	for (int i = 0; i < errors->num_errors; i++) {
		sprintf_s(errors->error_str, 1024, errors->errors[i]);
		if (i != errors->num_errors - 1) sprintf_s(errors->error_str, 1024, "\r\n");
	}
    // char ret_val[1024 * 16];
    // sprintf_s(ret_val, sizeof(ret_val), errors->error_str);
//    printf("ERROR: %s\r\n", ret_val);
    printf("____________________ERROR %s_____________________________________\r\n", errors->error_str);
    return errors->error_str;
}
void report(synch_errors_p errors, char* error) {
    errors->errors[errors->num_errors] = (char*)malloc(1024*sizeof(char));
    sprintf_s(errors->errors[errors->num_errors], 1024, error);
    printf("Reporting %s", error);
    errors->num_errors++;
    errors->has_errors=true;
    // print_errors(errors, false);
}
void report_last(synch_errors_p errors, char* error) {
    // printf("REPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRINGREPORTING REPORTING REPORTING REPOTRING")
    char *e = (char*)malloc(sizeof(char) * 1024);
    sprintf_s(e, 1024, "%s Error: %u", error, GetLastError()); 
    printf("Reporting: %s\r\n\r\n\r\n", e);
    report(errors, e);
}
/*
* See: https://docs.microsoft.com/en-us/windows/win32/secauthz/creating-a-security-descriptor-for-a-new-object-in-c--?redirectedfrom=MSDN
* IPC Access
*/
PSECURITY_ATTRIBUTES get_ipc_sd(synch_errors_p error) {
    DWORD dwRes, dwDisposition;
    PSID pEveryoneSID = NULL;
    PACL pACL = NULL;
    PSECURITY_DESCRIPTOR pSD = NULL;
    EXPLICIT_ACCESS ea[2];
    SID_IDENTIFIER_AUTHORITY SIDAuthWorld =
            SECURITY_WORLD_SID_AUTHORITY;
    SID_IDENTIFIER_AUTHORITY SIDAuthNT = SECURITY_NT_AUTHORITY;
    SECURITY_ATTRIBUTES sa;
    LONG lRes;
    HKEY hkSub = NULL;

    // Create a well-known SID for the Everyone group.
    if(!AllocateAndInitializeSid(&SIDAuthWorld, 1,
                     SECURITY_WORLD_RID,
                     0, 0, 0, 0, 0, 0, 0,
                     &pEveryoneSID)) {
                         report_last(error, "AllocateAndInitializeSid Error");
                         goto Cleanup;
                     }
    ZeroMemory(&ea, sizeof(EXPLICIT_ACCESS));
    ea->grfAccessPermissions = KEY_ALL_ACCESS;
    ea->grfAccessMode = SET_ACCESS;
    ea->grfInheritance = INHERIT_NO_PROPAGATE;
    ea->Trustee.TrusteeForm = TRUSTEE_IS_SID;
    ea->Trustee.TrusteeType = TRUSTEE_IS_WELL_KNOWN_GROUP;
    ea->Trustee.ptstrName = (LPTSTR) pEveryoneSID;
    if(!SetEntriesInAcl(2, ea, NULL, &pACL) != ERROR_SUCCESS) {
        report_last(error, "SetEntriesInAcl");
        goto Cleanup;
    }

    pSD = (PSECURITY_DESCRIPTOR) LocalAlloc(LPTR, SECURITY_DESCRIPTOR_MIN_LENGTH);
    if(pSD == NULL) {
        report_last(error, "LocalAlloc Error");
        goto Cleanup;
    }
    if(!InitializeSecurityDescriptor(pSD, SECURITY_DESCRIPTOR_REVISION)) {
        report_last(error, "InitializeSecurityDescriptor");
        goto Cleanup;
    }
    if(!SetSecurityDescriptorDacl(pSD, TRUE, pACL, FALSE)) {
        report_last(error, "SetSecurityDescriptorDacl");
        goto Cleanup;
    }
    PSECURITY_ATTRIBUTES ret_val;
    ret_val = (PSECURITY_ATTRIBUTES)malloc( sizeof(SECURITY_ATTRIBUTES));
    ret_val->lpSecurityDescriptor = pSD;
    ret_val->bInheritHandle = true;
    ret_val->nLength = sizeof(ret_val);
    return ret_val;
    Cleanup:
    if (pEveryoneSID) 
        FreeSid(pEveryoneSID);
    if (pACL) 
        LocalFree(pACL);
    if (pSD) 
        LocalFree(pSD);
    return NULL;
}

synch_errors_p get_reporter() {
    synch_errors_p errors = (synch_errors_p)malloc(sizeof(synch_errors_t));
	errors->num_errors = 0;
    errors->has_errors = false;
	errors->errors = (char**)malloc(sizeof(char) * 1024 * 16);
    return errors;
}
LIB_EXPORT bool synch_errored(synch_handle_p handle) {
    return handle->reporter->has_errors;
}
LIB_EXPORT char* synch_get_errors(synch_handle_p handle) {
    char* ret_val = print_errors(handle->reporter);
    handle->reporter = get_reporter();
    return ret_val;
}
LIB_EXPORT synch_handle_p event_create(char* name) {
    synch_handle_p evt = (synch_handle_p)malloc(sizeof(synch_handle_t));
    evt->reporter = get_reporter();
    evt->handle = CreateEvent(get_ipc_sd(evt->reporter), true, false, name);
    if(evt->handle == NULL){
        report_last(evt->reporter, "CreateEvent");
        printf("Failed to create event");
    } else {
        printf("event created successfully\r\n");
    }
    return evt;
}
LIB_EXPORT void event_signal(synch_handle_p handle) {
    if(!SetEvent(handle->handle)) {
        report_last(handle->reporter, "SetEvent");
    }
}
LIB_EXPORT void event_reset(synch_handle_p handle) {
    if(!ResetEvent(handle->handle)) {
        report_last(handle->reporter, "ResetEvent");
    }
}

LIB_EXPORT synch_handle_p event_open(char* name) {
    synch_handle_p evt = (synch_handle_p)malloc(sizeof(synch_handle_t));
    evt->handle = OpenEventA(SYNCHRONIZE, true, name);
    if(evt->handle == NULL) {
        report_last(evt->reporter, "OpenEvent");
    }
    return evt;
}
LIB_EXPORT void synch_close_handle(synch_handle_p handle) {
    CloseHandle(handle->handle);
}
LIB_EXPORT void synch_wait_for_handle(synch_handle_p handle, DWORD duration) {
    handle->wait_status = WaitForSingleObject(handle->handle, duration);
    if(handle->wait_status == WAIT_FAILED) {
       // printf("Failed to wait!\r\n");
        report_last(handle->reporter, "WaitForSingleObject");
    }
    else {
       // printf("Wait successful!\r\n");
    }
}
LIB_EXPORT void synch_gather_handle(synch_handle_p s, synch_handle_p t) {
    if(!s->gather_started) {
        s->capacity = sizeof(HANDLE) * 16;
        s->gathered = (HANDLE*)malloc(s->capacity);
        s->gather_count = 0;
        s->gather_started=true;
    }
    const int handles = s->capacity / sizeof(HANDLE);
    if(s->gather_count * sizeof(HANDLE) >= s->capacity) {
        s->capacity = s->capacity + (sizeof(HANDLE) * 16);
        s->gathered = (HANDLE*)realloc(s->gathered, s->capacity);
    }
    s->gathered[s->gather_count] = t->handle;
    s->gather_count++;
}
LIB_EXPORT void synch_wait_for_many(synch_handle_p handle, DWORD duration, bool wait_all) {
    const HANDLE* handles = handle->gathered;
    handle->wait_status = WaitForMultipleObjects(handle->gather_count, handles, wait_all, duration);
    if(handle->wait_status == WAIT_FAILED) {
        report_last(handle->reporter, "WaitForMultipleObjects");
    }
    else {
        handle->gather_started = false;
    }
}
LIB_EXPORT bool critical_section_errored(critical_section_p critical_section) {
    return critical_section->reporter->has_errors;
}
LIB_EXPORT char * critical_section_get_errors(critical_section_p critical_section) {
    char* ret_val = print_errors(critical_section->reporter);
    critical_section->reporter = get_reporter();
    return ret_val;
}

LIB_EXPORT critical_section_p critical_section_init(DWORD spin_count) {
    critical_section_p section = (critical_section_p)malloc(sizeof(critical_section_t));
    section->reporter = get_reporter();
    section->spin_count = spin_count;
    section->critical_section = (LPCRITICAL_SECTION)malloc(sizeof(CRITICAL_SECTION));
    if(!InitializeCriticalSectionAndSpinCount(section->critical_section, spin_count)) {
        
        report_last(section->reporter, "InitializeCriticalSectionAndSpinCount");
    } 
    return section;
}
LIB_EXPORT void critical_section_enter(critical_section_p ctx) {
    EnterCriticalSection(ctx->critical_section);
}
LIB_EXPORT bool critical_section_try_enter(critical_section_p ctx) {
    return TryEnterCriticalSection(ctx->critical_section);
}
LIB_EXPORT void critical_section_leave(critical_section_p ctx) {
    // printf("Leaving critical section\r\n");
    LeaveCriticalSection(ctx->critical_section);
}

LIB_EXPORT void critical_section_delete(critical_section_p ctx) {
    DeleteCriticalSection(ctx->critical_section);
}

LIB_EXPORT bool synch_barrier_errored(barrier_p barrier) {
    return barrier->reporter->has_errors;
}
LIB_EXPORT char* synch_barrier_get_errors(barrier_p barrier) {
    char* ret_val = print_errors(barrier->reporter);
    barrier->reporter=get_reporter();
    return ret_val;
}
LIB_EXPORT barrier_p  synch_barrier_init(DWORD threads, DWORD spin_count) {
    barrier_p barrier = (barrier_p)malloc(sizeof(barrier_t));
    barrier->reporter = get_reporter();
    barrier->threads = threads;
    barrier->spin_count = spin_count;
    barrier->barrier = (LPSYNCHRONIZATION_BARRIER)malloc(sizeof(SYNCHRONIZATION_BARRIER));
    if(!InitializeSynchronizationBarrier(barrier->barrier, threads, spin_count)) {
        report_last(barrier->reporter, "InitializeSynchronizationBarrier");
    }
    return barrier;
}
LIB_EXPORT bool synch_barrier_enter(barrier_p barrier, bool spin_only, bool block_only) {
    DWORD flags;
    if(spin_only) flags = SYNCHRONIZATION_BARRIER_FLAGS_SPIN_ONLY;
    else if(block_only) flags = SYNCHRONIZATION_BARRIER_FLAGS_BLOCK_ONLY;
    return EnterSynchronizationBarrier(barrier->barrier, flags);
    
}

LIB_EXPORT void synch_barrier_delete(barrier_p barrier) {
    if(!DeleteSynchronizationBarrier(barrier->barrier)) {
        report_last(barrier->reporter, "DeleteSynchronizationBarrier");
    }
}
LIB_EXPORT synch_handle_p mutex_create(const char* name, bool initial_owner) {
    synch_handle_p mutex = (synch_handle_p)malloc(sizeof(synch_handle_t));
    mutex->reporter = get_reporter();
    mutex->handle = CreateMutex(get_ipc_sd(mutex->reporter), initial_owner, name);
    if(mutex->handle == NULL) {
        report_last(mutex->reporter, "CreateMutex");
    }
    return mutex;
}
LIB_EXPORT synch_handle_p mutex_open(const char* name, bool initial_owner) {
    synch_handle_p mutex = (synch_handle_p)malloc(sizeof(synch_handle_t));
    mutex->reporter = get_reporter();
    mutex->handle = OpenMutex(SYNCHRONIZE, initial_owner, name);
    if(mutex->handle == NULL) {
        report_last(mutex->reporter, "CreateMutex");
    }
    return mutex;
}
LIB_EXPORT void mutex_release(synch_handle_p mutex) {
    if(!ReleaseMutex(mutex->handle)) {
        report_last(mutex->reporter, "ReleaseMutex");
    }
}
LIB_EXPORT bool srw_errored(srw_lock_p srw) {
    return srw->reporter->has_errors;
}

LIB_EXPORT char* srw_get_errors(srw_lock_p srw) {
    char* ret_val = print_errors(srw);
    srw->reporter = get_reporter();
    return ret_val;
}
LIB_EXPORT srw_lock_p srw_init_lock() {
    srw_lock_p srw = (srw_lock_p)malloc(sizeof(srw_lock_t));
    srw->reporter =get_reporter();
    srw->lock=(PSRWLOCK)malloc(sizeof(SRWLOCK));
    InitializeSRWLock(srw->lock);
    if(srw->lock == NULL) {
        report_last(srw->reporter, "InitializeSRWLock");
    }
    return srw;
}
LIB_EXPORT bool srw_try_acquire_exclusive(srw_lock_p srw) {
    return TryAcquireSRWLockExclusive(srw->lock);
}
LIB_EXPORT bool srw_try_acquire_shared(srw_lock_p srw) {
    return TryAcquireSRWLockShared(srw->lock);
}
LIB_EXPORT void srw_release_exclusive(srw_lock_p srw) {
    ReleaseSRWLockExclusive(srw->lock);
}
LIB_EXPORT void srw_release_shared(srw_lock_p srw) {
    ReleaseSRWLockShared(srw->lock);
}
LIB_EXPORT void srw_acquire_exclusive(srw_lock_p srw) {
    AcquireSRWLockExclusive(srw->lock);
}
LIB_EXPORT void srw_acquire_shared(srw_lock_p srw) {
    AcquireSRWLockShared(srw->lock);
}


