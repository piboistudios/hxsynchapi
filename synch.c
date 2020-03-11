#include "synch.h"

/*
* Errors
*/

void report(synch_errors_p errors, char* error) {
    errors->errors[errors->num_errors] = (char*)malloc(1024*sizeof(char));
    sprintf_s(errors->errors[errors->num_errors], "%s",error);
    errors->num_errors++;
    errors->has_errors=true;
}
void report_last(synch_errors_p errors, char* error) {
    char *e = (char*)malloc(sizeof(char) * 1024);
    sprintf_s(e, "%s Error: %u", error, GetLastError());
    report(errors, e);
}
char* print_errors(synch_errors_p errors, bool no_reset) {
	for (int i = 0; i < errors->num_errors; i++) {
		sprintf_s(errors->error_str, sizeof(errors->error_str), errors->errors[i]);
		if (i != errors->num_errors - 1) sprintf_s(errors->error_str, sizeof(errors->error_str), "\r\n");
	}
    char ret_val[1024 * 16];
    sprintf_s(ret_val, sizeof(ret_val), errors->error_str);
    return ret_val;
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
    if(SetEntriesInAcl(2, ea, NULL, &pACL) != ERROR_SUCCESS) {
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
    ZeroMemory(ret_val, sizeof(SECURITY_ATTRIBUTES));
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
	errors->errors = (char**)malloc(sizeof(char) * 1024 * 16);
    return errors;
}

LIB_EXPORT synch_handle_p create_event(char* name) {
    synch_handle_p handle = (synch_handle_p)malloc(sizeof(synch_handle_t));
    handle->errors = get_reporter();
    handle->handle = CreateEventA(get_ipc_sd(handle->errors), true, true, name);
    if(handle->handle == NULL){
        report_last(handle->errors, "CreateEvent");
    }
    return handle;
}
LIB_EXPORT void signal_event(synch_handle_p handle) {
    if(!SetEvent(handle->handle)) {
        report_last(handle->errors, "SetEvent");
    }
}
LIB_EXPORT void reset_event(synch_handle_p handle) {
    if(!ResetEvent(handle->handle)) {
        report_last(handle->errors, "ResetEvent");
    }
}

LIB_EXPORT synch_handle_p open_event(char* name) {
    synch_handle_p handle = (synch_handle_p)malloc(sizeof(synch_handle_t));
    handle->handle = OpenEventA(SYNCHRONIZE, true, name);
    if(handle->handle == NULL) {
        report_last(handle->errors, "OpenEvent");
    }
    return handle;
}

// LIB_EXPORT void wait_for_handle(synch_handle_p handle) {

// }