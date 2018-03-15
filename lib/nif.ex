defmodule LibrsyncEx.Nif do
  require Logger

  @dialyzer {:nowarn_function, nif_loaded: 0}

  @on_load :load_nif

  def load_nif do
    filename = "librsync_ex_nif"

    nif_path =
      :librsync_ex
      |> :code.priv_dir()
      |> List.to_string()
      |> Path.join(filename)
      |> String.to_charlist()

    case :erlang.load_nif(nif_path, 0) do
      :ok ->
        :ok
      error ->
        :ok = Logger.error "(LibrsyncEx) Error loading nif library: #{inspect error, pretty: true}."
        :ok
    end
  end

  @spec nif_loaded() :: boolean
  def nif_loaded() do
    false
  end

  @spec nif_rs_sig_file(String.t, String.t, pos_integer, pos_integer, LibrsyncEx.signature_format) :: :ok | {:error, any}
  def nif_rs_sig_file(_old_filename, _sig_filename, _block_len, _strong_sum_len, _format) do
    :erlang.nif_error "NIF nif_rs_sig_file/5 not implemented."
  end

  @spec nif_rs_delta_file(String.t, String.t, String.t) :: :ok | {:error, any}
  def nif_rs_delta_file(_sig_filename, _new_filename, _delta_filename) do
    :erlang.nif_error "NIF nif_rs_delta_file/3 not implemented."
  end

  @spec nif_rs_patch_file(String.t, String.t, String.t) :: :ok | {:error, any}
  def nif_rs_patch_file(_basis_filename, _delta_filename, _new_filename) do
    :erlang.nif_error "NIF nif_rs_patch_file/3 not implemented."
  end
end
