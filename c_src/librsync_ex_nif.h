#ifndef LIBRSYNC_EX
#define LIBRSYNC_EX

#include <erl_nif.h>

static ERL_NIF_TERM ATOM_ERROR;
static ERL_NIF_TERM ATOM_OK;

// Resources
// None currently defined

// NIF API Functions
// No args - return true.
static ERL_NIF_TERM ex_pc_prox_nif_loaded(ErlNifEnv *env, int argc,
                                          const ERL_NIF_TERM argv[]);

// No args - return :ok on success or {:error, reason}
static ERL_NIF_TERM ex_pc_prox_init(ErlNifEnv *env, int argc,
                                    const ERL_NIF_TERM argv[]);


#endif
