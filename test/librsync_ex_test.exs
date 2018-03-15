defmodule LibrsyncExTest do
  use ExUnit.Case
  doctest LibrsyncEx

  @md4_magic_number 0x72730136
  @blake2_magic_number 0x72730137

  setup do
    path = Path.join(System.tmp_dir!(), "librsync_ex_test")

    File.mkdir_p!(path)

    on_exit fn ->
      File.rm_rf! path
    end

    {:ok, path: path}
  end

  describe "build_signature_file" do
    setup %{path: path} do
      contents = "I am a test file!"
      filepath = Path.join(path, "build_signature_file-test")
      File.write!(filepath, contents)

      {:ok, filepath: filepath}
    end

    test "default format is BLAKE2", %{path: path, filepath: filepath} do
      sig_path = Path.join(path, "test-signature")
      assert :ok = LibrsyncEx.build_signature_file(filepath, sig_path)
      assert {:ok, sig} = File.read(sig_path)

      # Format is first 4 bytes of signature file
      <<format::size(32), _rest::binary>> = sig
      assert format == @blake2_magic_number
    end

    test "format can be set to md4", %{path: path, filepath: filepath} do
      sig_path = Path.join(path, "test-signature")
      assert :ok = LibrsyncEx.build_signature_file(filepath, sig_path, format: :md4)
      assert {:ok, sig} = File.read(sig_path)

      # Format is first 4 bytes of signature file
      <<format::size(32), _rest::binary>> = sig
      assert format == @md4_magic_number
    end

    test "default block length of 2048", %{path: path, filepath: filepath} do
      sig_path = Path.join(path, "test-signature")
      assert :ok = LibrsyncEx.build_signature_file(filepath, sig_path)
      assert {:ok, sig} = File.read(sig_path)

      # Block size is a 4-byte value stored after the format portion.
      <<_format::size(32), block_len::size(32), _rest::binary>> = sig

      assert block_len == 2048
    end

    test "block length can be changed", %{path: path, filepath: filepath} do
      sig_path = Path.join(path, "test-signature")
      assert :ok = LibrsyncEx.build_signature_file(filepath, sig_path, block_length: 128)
      assert {:ok, sig} = File.read(sig_path)

      # Block size is a 4-byte value stored after the format portion.
      <<_::size(32), block_len::size(32), _rest::binary>> = sig
      assert block_len == 128
    end
  end

  describe "end-to-end, 1K of data" do
    setup %{path: path} do
      original = :crypto.strong_rand_bytes(1024)
      filepath = Path.join(path, "1024-byte-data")
      File.write!(filepath, original)

      {:ok, filepath: filepath}
    end

    test "change first byte", %{path: path, filepath: filepath} do
      assert {:ok, original} = File.read(filepath)
      <<_::binary-size(1), rest::binary>> = original

      new_version = "Z" <> rest
      changed_filepath = Path.join(path, "1024-byte-data-updated")
      File.write!(changed_filepath, new_version)

      sigpath = Path.join(path, "1024-byte-data-signature")
      deltapath = Path.join(path, "1024-byte-data-to-updated-delta")
      patchedpath = Path.join(path, "1024-byte-data-patched")

      assert :ok = LibrsyncEx.build_signature_file(filepath, sigpath)
      assert :ok = LibrsyncEx.build_delta_file(sigpath, changed_filepath, deltapath)
      assert :ok = LibrsyncEx.patch_file(filepath, deltapath, patchedpath)

      assert {:ok, updated} = File.read(patchedpath)

      assert updated == new_version
    end

    test "change last byte", %{path: path, filepath: filepath} do
      assert {:ok, original} = File.read(filepath)
      <<rest::binary-size(1023), _::binary>> = original
      new_version = rest <> "Z"
      changed_filepath = Path.join(path, "1024-byte-data-updated")
      File.write!(changed_filepath, new_version)

      sigpath = Path.join(path, "1024-byte-data-signature")
      deltapath = Path.join(path, "1024-byte-data-to-updated-delta")
      patchedpath = Path.join(path, "1024-byte-data-patched")

      assert :ok = LibrsyncEx.build_signature_file(filepath, sigpath)
      assert :ok = LibrsyncEx.build_delta_file(sigpath, changed_filepath, deltapath)
      assert :ok = LibrsyncEx.patch_file(filepath, deltapath, patchedpath)

      assert {:ok, updated} = File.read(patchedpath)
      assert updated == new_version
    end

    test "change byte in the middle", %{path: path, filepath: filepath} do
      assert {:ok, original} = File.read(filepath)
      <<first::binary-size(511), _::binary-size(1), rest::binary>> = original
      new_version = first <> "Z" <> rest
      changed_filepath = Path.join(path, "1024-byte-data-updated")
      File.write!(changed_filepath, new_version)

      sigpath = Path.join(path, "1024-byte-data-signature")
      deltapath = Path.join(path, "1024-byte-data-to-updated-delta")
      patchedpath = Path.join(path, "1024-byte-data-patched")

      assert :ok = LibrsyncEx.build_signature_file(filepath, sigpath)
      assert :ok = LibrsyncEx.build_delta_file(sigpath, changed_filepath, deltapath)
      assert :ok = LibrsyncEx.patch_file(filepath, deltapath, patchedpath)

      assert {:ok, updated} = File.read(patchedpath)
      assert updated == new_version
    end
  end

  describe "end-to-end 10K bytes of data"do
    setup %{path: path} do
      original = :crypto.strong_rand_bytes(10240)
      filepath = Path.join(path, "10240-byte-data")
      File.write!(filepath, original)

      {:ok, filepath: filepath}
    end

    test "change first byte", %{path: path, filepath: filepath} do
      assert {:ok, original} = File.read(filepath)
      <<_::binary-size(1), rest::binary>> = original

      new_version = "Z" <> rest
      changed_filepath = Path.join(path, "10240-byte-data-updated")
      File.write!(changed_filepath, new_version)

      sigpath = Path.join(path, "10240-byte-data-signature")
      deltapath = Path.join(path, "10240-byte-data-to-updated-delta")
      patchedpath = Path.join(path, "10240-byte-data-patched")

      assert :ok = LibrsyncEx.build_signature_file(filepath, sigpath)
      assert :ok = LibrsyncEx.build_delta_file(sigpath, changed_filepath, deltapath)
      assert :ok = LibrsyncEx.patch_file(filepath, deltapath, patchedpath)

      assert {:ok, updated} = File.read(patchedpath)

      assert updated == new_version
    end

    test "change last byte", %{path: path, filepath: filepath} do
      assert {:ok, original} = File.read(filepath)
      <<rest::binary-size(10239), _::binary>> = original
      new_version = rest <> "Z"
      changed_filepath = Path.join(path, "10240-byte-data-updated")
      File.write!(changed_filepath, new_version)

      sigpath = Path.join(path, "10240-byte-data-signature")
      deltapath = Path.join(path, "10240-byte-data-to-updated-delta")
      patchedpath = Path.join(path, "10240-byte-data-patched")

      assert :ok = LibrsyncEx.build_signature_file(filepath, sigpath)
      assert :ok = LibrsyncEx.build_delta_file(sigpath, changed_filepath, deltapath)
      assert :ok = LibrsyncEx.patch_file(filepath, deltapath, patchedpath)

      assert {:ok, updated} = File.read(patchedpath)
      assert updated == new_version
    end

    test "change byte in the middle", %{path: path, filepath: filepath} do
      assert {:ok, original} = File.read(filepath)
      <<first::binary-size(5119), _::binary-size(1), rest::binary>> = original
      new_version = first <> "Z" <> rest
      changed_filepath = Path.join(path, "10240-byte-data-updated")
      File.write!(changed_filepath, new_version)

      sigpath = Path.join(path, "10240-byte-data-signature")
      deltapath = Path.join(path, "10240-byte-data-to-updated-delta")
      patchedpath = Path.join(path, "10240-byte-data-patched")

      assert :ok = LibrsyncEx.build_signature_file(filepath, sigpath)
      assert :ok = LibrsyncEx.build_delta_file(sigpath, changed_filepath, deltapath)
      assert :ok = LibrsyncEx.patch_file(filepath, deltapath, patchedpath)

      assert {:ok, updated} = File.read(patchedpath)
      assert updated == new_version
    end
  end

  describe "end-to-end 100K bytes of data" do
    setup %{path: path} do
      original = :crypto.strong_rand_bytes(102400)
      filepath = Path.join(path, "102400-byte-data")
      File.write!(filepath, original)

      {:ok, filepath: filepath}
    end

    test "change first byte", %{path: path, filepath: filepath} do
      assert {:ok, original} = File.read(filepath)
      <<_::binary-size(1), rest::binary>> = original

      new_version = "Z" <> rest
      changed_filepath = Path.join(path, "102400-byte-data-updated")
      File.write!(changed_filepath, new_version)

      sigpath = Path.join(path, "102400-byte-data-signature")
      deltapath = Path.join(path, "102400-byte-data-to-updated-delta")
      patchedpath = Path.join(path, "102400-byte-data-patched")

      assert :ok = LibrsyncEx.build_signature_file(filepath, sigpath)
      assert :ok = LibrsyncEx.build_delta_file(sigpath, changed_filepath, deltapath)
      assert :ok = LibrsyncEx.patch_file(filepath, deltapath, patchedpath)

      assert {:ok, updated} = File.read(patchedpath)

      assert updated == new_version
    end

    test "change last byte", %{path: path, filepath: filepath} do
      assert {:ok, original} = File.read(filepath)
      <<rest::binary-size(102399), _::binary>> = original
      new_version = rest <> "Z"
      changed_filepath = Path.join(path, "102400-byte-data-updated")
      File.write!(changed_filepath, new_version)

      sigpath = Path.join(path, "102400-byte-data-signature")
      deltapath = Path.join(path, "102400-byte-data-to-updated-delta")
      patchedpath = Path.join(path, "102400-byte-data-patched")

      assert :ok = LibrsyncEx.build_signature_file(filepath, sigpath)
      assert :ok = LibrsyncEx.build_delta_file(sigpath, changed_filepath, deltapath)
      assert :ok = LibrsyncEx.patch_file(filepath, deltapath, patchedpath)

      assert {:ok, updated} = File.read(patchedpath)
      assert updated == new_version
    end

    test "change byte in the middle", %{path: path, filepath: filepath} do
      assert {:ok, original} = File.read(filepath)
      <<first::binary-size(51199), _::binary-size(1), rest::binary>> = original
      new_version = first <> "Z" <> rest
      changed_filepath = Path.join(path, "102400-byte-data-updated")
      File.write!(changed_filepath, new_version)

      sigpath = Path.join(path, "102400-byte-data-signature")
      deltapath = Path.join(path, "102400-byte-data-to-updated-delta")
      patchedpath = Path.join(path, "102400-byte-data-patched")

      assert :ok = LibrsyncEx.build_signature_file(filepath, sigpath)
      assert :ok = LibrsyncEx.build_delta_file(sigpath, changed_filepath, deltapath)
      assert :ok = LibrsyncEx.patch_file(filepath, deltapath, patchedpath)

      assert {:ok, updated} = File.read(patchedpath)
      assert updated == new_version
    end
  end

  describe "end-to-end 1M bytes of data" do
    setup %{path: path} do
      original = :crypto.strong_rand_bytes(1024 * 1024)
      filepath = Path.join(path, "1048576-byte-data")
      File.write!(filepath, original)

      {:ok, filepath: filepath}
    end

    test "change first byte", %{path: path, filepath: filepath} do
      assert {:ok, original} = File.read(filepath)
      <<_::binary-size(1), rest::binary>> = original

      new_version = "Z" <> rest
      changed_filepath = Path.join(path, "1048576-byte-data-updated")
      File.write!(changed_filepath, new_version)

      sigpath = Path.join(path, "1048576-byte-data-signature")
      deltapath = Path.join(path, "1048576-byte-data-to-updated-delta")
      patchedpath = Path.join(path, "1048576-byte-data-patched")

      assert :ok = LibrsyncEx.build_signature_file(filepath, sigpath)
      assert :ok = LibrsyncEx.build_delta_file(sigpath, changed_filepath, deltapath)
      assert :ok = LibrsyncEx.patch_file(filepath, deltapath, patchedpath)

      assert {:ok, updated} = File.read(patchedpath)

      assert updated == new_version
    end

    test "change last byte", %{path: path, filepath: filepath} do
      assert {:ok, original} = File.read(filepath)
      <<rest::binary-size(1048575), _::binary>> = original
      new_version = rest <> "Z"
      changed_filepath = Path.join(path, "1048576-byte-data-updated")
      File.write!(changed_filepath, new_version)

      sigpath = Path.join(path, "1048576-byte-data-signature")
      deltapath = Path.join(path, "1048576-byte-data-to-updated-delta")
      patchedpath = Path.join(path, "1048576-byte-data-patched")

      assert :ok = LibrsyncEx.build_signature_file(filepath, sigpath)
      assert :ok = LibrsyncEx.build_delta_file(sigpath, changed_filepath, deltapath)
      assert :ok = LibrsyncEx.patch_file(filepath, deltapath, patchedpath)

      assert {:ok, updated} = File.read(patchedpath)
      assert updated == new_version
    end

    test "change byte in the middle", %{path: path, filepath: filepath} do
      assert {:ok, original} = File.read(filepath)
      <<first::binary-size(524287), _::binary-size(1), rest::binary>> = original
      new_version = first <> "Z" <> rest
      changed_filepath = Path.join(path, "1048576-byte-data-updated")
      File.write!(changed_filepath, new_version)

      sigpath = Path.join(path, "1048576-byte-data-signature")
      deltapath = Path.join(path, "1048576-byte-data-to-updated-delta")
      patchedpath = Path.join(path, "1048576-byte-data-patched")

      assert :ok = LibrsyncEx.build_signature_file(filepath, sigpath)
      assert :ok = LibrsyncEx.build_delta_file(sigpath, changed_filepath, deltapath)
      assert :ok = LibrsyncEx.patch_file(filepath, deltapath, patchedpath)

      assert {:ok, updated} = File.read(patchedpath)
      assert updated == new_version
    end
  end
end
