defmodule LibrsyncEx do
  @moduledoc """
  Documentation for LibrsyncEx.
  """
  require Logger

  @dialyzer {:nowarn_function, check_nif_loaded: 0}

  @type signature_format :: :blake2 | :md4

  @type signature_opts :: [
    block_length: pos_integer,
    strong_sum_length: pos_integer,
    format: signature_format
  ]

  # From librsync.h
  @default_block_length 2048
  @default_strong_sum_length 0
  @default_format :blake2

  @spec build_signature_file(String.t, String.t, signature_opts) :: :ok | {:error, any}
  def build_signature_file(old_filename, signature_filename, opts \\ []) do
    # Ensure the old file exists before trying to calculate its signature.
    with {:old_file, true} <- {:old_file, File.exists?(old_filename)},
         {:lib, true} <- check_nif_loaded() do
      block_length = Keyword.get(opts, :block_length, @default_block_length)
      strong_sum_length = Keyword.get(opts, :strong_sum_length, @default_strong_sum_length)
      format = Keyword.get(opts, :format, @default_format)

      LibrsyncEx.Nif.nif_rs_sig_file(
        String.to_charlist(old_filename),
        String.to_charlist(signature_filename),
        block_length,
        strong_sum_length,
        format)
    else
      {:old_file, false} ->
        :ok = Logger.error "(LibrsyncEx) Couldn't get signature for #{old_filename}. File does not exist."
        {:error, :enoent}
      {:lib, false} ->
        :ok = Logger.error "(LibrsyncEx) NIF library not loaded."
        {:error, :nif_not_loaded}
    end
  end

  def build_delta_file(signature_filename, new_filename, delta_filename) do
    # Ensure the signature and new files exist before we try to calculate a
    # delta.
    with {:sig_file, true} <- {:sig_file, File.exists?(signature_filename)},
         {:new_file, true} <- {:new_file, File.exists?(new_filename)},
         {:lib, true} <- check_nif_loaded() do
      LibrsyncEx.Nif.nif_rs_delta_file(
        String.to_charlist(signature_filename),
        String.to_charlist(new_filename),
        String.to_charlist(delta_filename))
    else
      {:sig_file, false} ->
        :ok = Logger.error "(LibrsyncEx) Couldn't build delta file from signature file #{signature_filename}. Signature file does not exist."
        {:error, :enoent}
      {:new_file, false} ->
        :ok = Logger.error "(LibrsyncEx) Couldn't build delta file from 'new' file: #{new_filename}. 'New' file does not exist."
        {:error, :enoent}
      {:lib, false} ->
        :ok = Logger.error "(LibrsyncEx) NIF library not loaded."
        {:error, :nif_not_loaded}
    end
  end

  def patch_file(basis_filename, delta_filename, new_filename) do
    # Ensure the basis and delta files exist before we try to calculate a new
    # file.
    with {:basis_file, true} <- {:basis_file, File.exists?(basis_filename)},
         {:delta_file, true} <- {:delta_file, File.exists?(delta_filename)},
         {:lib, true} <- check_nif_loaded() do
      LibrsyncEx.Nif.nif_rs_patch_file(
        String.to_charlist(basis_filename),
        String.to_charlist(delta_filename),
        String.to_charlist(new_filename))
    else
      {:basis_file, false} ->
        :ok = Logger.error "(LibrsyncEx) Couldn't patch basis file #{basis_filename}. File does not exist."
        {:error, :enoent}
      {:delta_file, false} ->
        :ok = Logger.error "(LibrsyncEx) Couldn't patch basis file with delta file: #{delta_filename}. Delta file does not exist."
        {:error, :enoent}
      {:lib, false} ->
        :ok = Logger.error "(LibrsyncEx) NIF library not loaded."
        {:error, :nif_not_loaded}
    end
  end

  @spec check_nif_loaded() :: {:lib, boolean}
  defp check_nif_loaded() do
    {:lib, LibrsyncEx.Nif.nif_loaded()}
  end
end
