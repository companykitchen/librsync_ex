#ifndef LIBRSYNC_EX
#define LIBRSYNC_EX

#include <erl_nif.h>
#include <librsync.h>

static ERL_NIF_TERM ATOM_ERROR;
static ERL_NIF_TERM ATOM_OK;

// Resources
// None currently defined

// NIF API Functions
// No args - return true.
static ERL_NIF_TERM librsync_ex_nif_loaded(ErlNifEnv *env, int argc,
                                          const ERL_NIF_TERM argv[]);

// No args - return :ok on success or {:error, reason}
static ERL_NIF_TERM librsync_ex_nif_init(ErlNifEnv *env, int argc,
                                    const ERL_NIF_TERM argv[]);


#endif
