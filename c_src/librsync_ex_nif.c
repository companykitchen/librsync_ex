#include "librsync_ex_nif.h"
#include <stdio.h>
#include <string.h>

// NIF lifecycle functions
static int load(ErlNifEnv *env, void **priv_data, ERL_NIF_TERM load_info) {
  ATOM_ERROR = enif_make_atom(env, "error");
  ATOM_OK = enif_make_atom(env, "ok");
  ATOM_TRUE = enif_make_atom(env, "true");

  ATOM_BLAKE2 = enif_make_atom(env, "blake2");
  ATOM_MD4 = enif_make_atom(env, "md4");

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
  // Get signature options
  size_t block_len = RS_DEFAULT_BLOCK_LEN;
  size_t strong_len = 0; // Using 0 lets librsync pick a value.
  rs_magic_number sig_magic_number = RS_BLAKE2_SIG_MAGIC;

  if (argc >= 3) {
    enif_get_ulong(env, argv[2], &block_len);
  }

  if (argc >= 4) {
  enif_get_ulong(env, argv[3], &strong_len);
  }

  if (argc >= 5) {
    char magic_number_atom[128];
    enif_get_atom(env, argv[4], magic_number_atom, 128, ERL_NIF_LATIN1);

    if (strcmp(magic_number_atom, "md4") == 0) {
      sig_magic_number = RS_MD4_SIG_MAGIC;
    }
  }

  // Get filenames
  uint old_fn_length, sig_fn_length;
  enif_get_list_length(env, argv[0], &old_fn_length);
  enif_get_list_length(env, argv[1], &sig_fn_length);

  // + 1 for null terminator
  char old_filename[old_fn_length + 1];
  char sig_filename[sig_fn_length + 1];

  enif_get_string(env, argv[0], old_filename, old_fn_length + 1, ERL_NIF_LATIN1);
  enif_get_string(env, argv[1], sig_filename, sig_fn_length + 1, ERL_NIF_LATIN1);

  FILE *old_file = fopen((const char*)old_filename, "r");
  FILE *sig_file = NULL;

  ERL_NIF_TERM nif_result;

  if (old_file == NULL) {
    nif_result = enif_make_tuple2(env, ATOM_ERROR, enif_make_int(env, RS_IO_ERROR));
  } else {
    sig_file = fopen((const char *)sig_filename, "w");

    rs_result result = rs_sig_file(old_file, sig_file, block_len, strong_len, sig_magic_number, NULL);

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
  uint sig_fn_length, new_fn_length, delta_fn_length;
  enif_get_list_length(env, argv[0], &sig_fn_length);
  enif_get_list_length(env, argv[1], &new_fn_length);
  enif_get_list_length(env, argv[2], &delta_fn_length);

  // + 1 for null terminator
  char sig_filename[sig_fn_length + 1];
  char new_filename[new_fn_length + 1];
  char delta_filename[delta_fn_length + 1];

  enif_get_string(env, argv[0], sig_filename, sig_fn_length + 1, ERL_NIF_LATIN1);
  enif_get_string(env, argv[1], new_filename, new_fn_length + 1, ERL_NIF_LATIN1);
  enif_get_string(env, argv[2], delta_filename, delta_fn_length + 1, ERL_NIF_LATIN1);

  FILE *sig_file = fopen(sig_filename, "r");
  FILE *new_file = fopen(new_filename, "r");
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
        delta_file = fopen(delta_filename, "w");
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
  uint basis_fn_length, delta_fn_length, new_fn_length;
  enif_get_list_length(env, argv[0], &basis_fn_length);
  enif_get_list_length(env, argv[1], &delta_fn_length);
  enif_get_list_length(env, argv[2], &new_fn_length);

  // + 1 for null terminator
  char basis_filename[basis_fn_length + 1];
  char delta_filename[delta_fn_length + 1];
  char new_filename[new_fn_length + 1];

  enif_get_string(env, argv[0], basis_filename, basis_fn_length + 1, ERL_NIF_LATIN1);
  enif_get_string(env, argv[1], delta_filename, delta_fn_length + 1, ERL_NIF_LATIN1);
  enif_get_string(env, argv[2], new_filename, new_fn_length + 1, ERL_NIF_LATIN1);

  FILE *basis_file = fopen(basis_filename, "r");
  FILE *delta_file = fopen(delta_filename, "r");
  FILE *new_file = NULL;

  ERL_NIF_TERM nif_result;

  if (basis_file == NULL || delta_file == NULL) {
    nif_result = enif_make_tuple2(env, ATOM_ERROR, enif_make_int(env, RS_IO_ERROR));
  } else {
    new_file = fopen(new_filename, "w");
    rs_result result = rs_patch_file(basis_file, delta_file, new_file, NULL);

    if (result == RS_DONE) {
      nif_result = ATOM_OK;
    } else {
      nif_result = enif_make_tuple2(env, ATOM_ERROR, enif_make_int(env, result));
    }
  }

  fclose(basis_file);
  fclose(delta_file);
  fclose(new_file);
  return nif_result;
}

ERL_NIF_INIT(Elixir.LibrsyncEx.Nif, nif_funcs, load, NULL, NULL, unload)