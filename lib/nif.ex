defmodule LibrsyncEx.Nif do
  require Logger

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
        Logger.error "(LibrsyncEx) Error loading nif library: #{inspect error, pretty: true}."
        :ok
    end
  end

  @spec nif_loaded() :: boolean
  def nif_loaded() do
    false
  end

  def nif_rs_sig_file(_old_filename, _sig_filename) do
    raise "NIF nif_rs_sig_file/2 not implemented."
  end

  def nif_rs_delta_file(_sig_filename, _new_filename, _delta_filename) do
    raise "NIF nif_rs_delta_file/3 not implemented."
  end

  def nif_rs_patch_file(_basis_filename, _delta_filename, _new_filename) do
    raise "NIF nif_rs_patch_file/3 not implemented."
  end
end
