defmodule LibrsyncExTest do
  use ExUnit.Case
  doctest LibrsyncEx

  setup do
    path = Path.join(System.tmp_dir!(), "librsync_ex_test")

    File.mkdir_p!(path)

    on_exit fn ->
      File.rm_rf! path
    end

    {:ok, path: path}
  end

  describe "1K of data" do
    setup %{path: path} do
      original = :crypto.strong_rand_bytes(1024)
      filepath = Path.join(path, "1024-byte-data")
      File.write!(filepath, original)

      {:ok, filepath: filepath}
    end

    test "end-to-end, change first byte", %{path: path, filepath: filepath} do
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

    test "end-to-end, change last byte", %{path: path, filepath: filepath} do
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

    test "end-to-end, change byte in the middle", %{path: path, filepath: filepath} do
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

    test "end-to-end, change first byte", %{path: path, filepath: filepath} do
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

    test "end-to-end, change last byte", %{path: path, filepath: filepath} do
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

    test "end-to-end, change byte in the middle", %{path: path, filepath: filepath} do
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

    test "end-to-end, change first byte", %{path: path, filepath: filepath} do
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

    test "end-to-end, change last byte", %{path: path, filepath: filepath} do
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

    test "end-to-end, change byte in the middle", %{path: path, filepath: filepath} do
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

    test "end-to-end, change first byte", %{path: path, filepath: filepath} do
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

    test "end-to-end, change last byte", %{path: path, filepath: filepath} do
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

    test "end-to-end, change byte in the middle", %{path: path, filepath: filepath} do
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
