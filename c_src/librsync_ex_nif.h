#ifndef LIBRSYNC_EX
#define LIBRSYNC_EX

#include <erl_nif.h>
#include <librsync.h>

static ERL_NIF_TERM ATOM_ERROR;
static ERL_NIF_TERM ATOM_OK;
static ERL_NIF_TERM ATOM_TRUE;

static ERL_NIF_TERM ATOM_BLAKE2;
static ERL_NIF_TERM ATOM_MD4;

// Resources
// None currently defined

// NIF API Functions
// No args - return true.
static ERL_NIF_TERM librsync_ex_nif_loaded(ErlNifEnv *env, int argc,
                                           const ERL_NIF_TERM argv[]);

// argv[0]: 'old file' - File whose signature will be generated.
// argv[1]: 'sig file' - Filename of file in which signature will be written.
// argv[2]: 'block len' - Integer size of blocks to use.
// argv[3]: 'strong len' - Integer size of truncated length of strong checksums.
// argv[4]: 'magic number' - Signature format identifier.
// Returns: :ok atom or {:error, rs_result status code}.
static ERL_NIF_TERM librsync_ex_nif_rs_sig_file(ErlNifEnv *env, int argc,
                                                const ERL_NIF_TERM argv[]);

// argv[0]: 'sig file' - Filename of signature file.
// argv[1]: 'new file' - Filename of new file to which the signature is applied,
// generating a delta file. argv[2]: 'delta file' - Filename of file in which
// delta will be written. Returns: :ok atom or {:error, rs_result status code}.
static ERL_NIF_TERM librsync_ex_nif_rs_delta_file(ErlNifEnv *env, int argc,
                                                  const ERL_NIF_TERM argv[]);

// argv[0]: 'basis file' - Filename of basis file to which the delta will be
// appliec. argv[1]: 'delta file' - Filename of delta file. argv[2]: 'new file'
// - Filename in which to write the new patched version of 'basis file'.
// Returns: :ok atom or {:error, rs_result status code}.
static ERL_NIF_TERM librsync_ex_nif_rs_patch_file(ErlNifEnv *env, int argc,
                                                  const ERL_NIF_TERM argv[]);

static ErlNifFunc nif_funcs[] = {
    {"nif_loaded", 0, librsync_ex_nif_loaded},
    {"nif_rs_sig_file", 5, librsync_ex_nif_rs_sig_file,
     ERL_NIF_DIRTY_JOB_IO_BOUND},
    {"nif_rs_delta_file", 3, librsync_ex_nif_rs_delta_file,
     ERL_NIF_DIRTY_JOB_IO_BOUND},
    {"nif_rs_patch_file", 3, librsync_ex_nif_rs_patch_file,
     ERL_NIF_DIRTY_JOB_IO_BOUND}};

#endif
