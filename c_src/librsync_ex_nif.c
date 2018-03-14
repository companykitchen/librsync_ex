#include "librsync_ex_nif.h"
#include <stdio.h>
#include <string.h>

// NIF lifecycle functions
static int load(ErlNifEnv *env, void **priv_data, ERL_NIF_TERM load_info) {
  ATOM_ERROR = enif_make_atom(env, "error");
  ATOM_OK = enif_make_atom(env, "ok");
  ATOM_TRUE = enif_make_atom(env, "true");

  return 0;
}

static void unload(ErlNifEnv *env, void *priv_data) {
  enif_free(priv_data);
  return;
}

// Our NIF functions
static ERL_NIF_TERM librsync_ex_nif_loaded(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  return ATOM_TRUE;
}

static ERL_NIF_TERM librsync_ex_nif_rs_sig_file(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary old_filename, sig_filename;
  enif_inspect_binary(env, argv[0], &old_filename);
  enif_inspect_binary(env, argv[1], &sig_filename);

  FILE *old_file = fopen((const char*)old_filename.data, "r");
  FILE *sig_file = NULL;

  ERL_NIF_TERM nif_result;

  if (old_file == NULL) {
    nif_result = enif_make_tuple2(env, ATOM_ERROR, enif_make_int(env, RS_IO_ERROR));
  } else {
    sig_file = fopen((const char *)sig_filename.data, "w");

    rs_result result = rs_sig_file(old_file, sig_file, RS_DEFAULT_BLOCK_LEN, RS_MAX_STRONG_SUM_LENGTH, RS_BLAKE2_SIG_MAGIC, NULL);

    if (result == RS_DONE) {
      nif_result = ATOM_OK;
    } else {
      nif_result = enif_make_tuple2(env, ATOM_ERROR, enif_make_int(env, result));
    }
  }

  fclose(old_file);
  fclose(sig_file);

  return nif_result;
}

static ERL_NIF_TERM librsync_ex_nif_rs_delta_file(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary sig_filename;
  ErlNifBinary new_filename;
  ErlNifBinary delta_filename;

  enif_inspect_binary(env, argv[0], &sig_filename);
  enif_inspect_binary(env, argv[1], &new_filename);
  enif_inspect_binary(env, argv[2], &delta_filename);

  FILE *sig_file = fopen((const char*)sig_filename.data, "r");
  FILE *new_file = fopen((const char*)new_filename.data, "r");
  FILE *delta_file = NULL;

  ERL_NIF_TERM nif_result;

  if (sig_file == NULL || new_file == NULL) {
    nif_result = enif_make_tuple2(env, ATOM_ERROR, enif_make_int(env, RS_IO_ERROR));
  } else {
    rs_signature_t *sumset;
    rs_result result = rs_loadsig_file(sig_file, &sumset, NULL);

    if (result != RS_DONE) {
      nif_result =  enif_make_tuple2(env, ATOM_ERROR, enif_make_int(env, result));
    } else {
      result = rs_build_hash_table(sumset);
      if (result != RS_DONE) {
        nif_result = enif_make_tuple2(env, ATOM_ERROR, enif_make_int(env, result));
      } else {
        delta_file = fopen((const char*)delta_filename.data, "w");
        result = rs_delta_file(sumset, new_file, delta_file, NULL);

        if (result == RS_DONE) {
          nif_result = ATOM_OK;
        } else {
          nif_result = enif_make_tuple2(env, ATOM_ERROR, enif_make_int(env, result));
        }
      }
    }
  }

  fclose(sig_file);
  fclose(new_file);
  fclose(delta_file);

  return nif_result;
}

static ERL_NIF_TERM librsync_ex_nif_rs_patch_file(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
  ErlNifBinary basis_filename;
  ErlNifBinary delta_filename;
  ErlNifBinary new_filename;

  enif_inspect_binary(env, argv[0], &basis_filename);
  enif_inspect_binary(env, argv[1], &delta_filename);
  enif_inspect_binary(env, argv[2], &new_filename);

  FILE *basis_file = fopen((const char*)basis_filename.data, "r");
  FILE *delta_file = fopen((const char*)delta_filename.data, "r");
  FILE *new_file = NULL;

  ERL_NIF_TERM nif_result;

  if (basis_file == NULL || delta_file == NULL) {
    printf("one of the files was NULL\n");
    nif_result = enif_make_tuple2(env, ATOM_ERROR, enif_make_int(env, RS_IO_ERROR));
  } else {
    new_file = fopen((const char*)new_filename.data, "w");
    rs_result result = rs_patch_file(basis_file, delta_file, new_file, NULL);

    if (result == RS_DONE) {
      nif_result = ATOM_OK;
    } else {
      printf("error doing the patch...\n");
      nif_result = enif_make_tuple2(env, ATOM_ERROR, enif_make_int(env, result));
    }
  }

  fclose(basis_file);
  fclose(delta_file);
  fclose(new_file);
  return nif_result;
}

ERL_NIF_INIT(Elixir.LibrsyncEx.Nif, nif_funcs, load, NULL, NULL, unload)