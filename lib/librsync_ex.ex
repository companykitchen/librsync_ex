defmodule LibrsyncEx do
  @moduledoc """
  Documentation for LibrsyncEx.
  """

  def build_signature_file(old_filename, signature_filename) do
    # Ensure the file exists before we try to generate a signature.
    if File.exists?(old_filename) == false do
      {:error, :enoent}
    else
      LibrsyncEx.Nif.nif_rs_sig_file(
        String.to_charlist(old_filename),
        String.to_charlist(signature_filename))
    end
  end

  def build_delta_file(signature_filename, new_filename, delta_filename) do
    # Ensure the signature and new files exist before we try to calculate a
    # delta.
    unless File.exists?(signature_filename) && File.exists?(new_filename) do
      {:error, :enoent}
    else
      LibrsyncEx.Nif.nif_rs_delta_file(
        String.to_charlist(signature_filename),
        String.to_charlist(new_filename),
        String.to_charlist(delta_filename))
    end
  end

  def patch_file(basis_filename, delta_filename, new_filename) do
    # Ensure the basis and delta files exist before we try to calculate a new
    # file.
    unless File.exists?(basis_filename) && File.exists?(delta_filename) do
      {:error, :enoent}
    else
      LibrsyncEx.Nif.nif_rs_patch_file(
        String.to_charlist(basis_filename),
        String.to_charlist(delta_filename),
        String.to_charlist(new_filename))
    end
  end
end
