defmodule Carrier.Credentials do
  alias Carrier.SecurityError
  alias Carrier.FileError
  alias Carrier.Util

  defstruct [:id, :private, :public]

  @private_key "carrier_priv.key"
  @public_key "carrier_pub.key"
  @carrier_id "carrier.id"

  # 32 byte key w/64 byte checksum
  @key_hash_size 64

  @doc "Validates the configured credential directory."
  @spec validate_files!() :: true | no_return()
  def validate_files!() do
    credentials_path = Application.get_env(:carrier, :credentials_dir)
    validate_files!(credentials_path)
  end

  @doc "Validates the directory structure and file permissions of credentials."
  def validate_files!(nil) do
    raise FileError.new("Credential root directory is nil")
  end
  def validate_files!(root) do
    if File.exists?(root) do
      if File.dir?(root) do
        ensure_correct_mode!(root, 0o40700)
        read_private_credentials!(root)
      else
        raise FileError.new("Path #{root} is not a directory")
      end
    else
      configure_credentials!(root)
    end
  end

  @doc "Generates a new private/public keypair"
  @spec generate() :: %__MODULE__{}
  def generate() do
    keys = :enacl.sign_keypair()
    %__MODULE__{id: UUID.uuid4(), private: keys.secret, public: keys.public}
  end

  @doc "Writes a credential set to disk"
  @spec write_public_credentials!(String.t(), %__MODULE__{}) :: :ok | no_return()
  def write_public_credentials!(path, %__MODULE__{id: id}=credentials) do
    public_path = Path.join(path, creds_file_name(id, :public))
    id_path = Path.join(path, creds_file_name(id, :id))
    write_data_checksum!(credentials.id, id_path)
    write_data_checksum!(credentials.public, public_path)
    :ok
  end

  @doc "Scans and reads all persisted credentials"
  @spec read_all_credentials!(String.t()) :: [] | Keyword.t() | no_return()
  def read_all_credentials!(root) do
    case scan(root) do
      [] ->
        []
      names ->
        Enum.map(names, fn(name) -> {name, read_public_credential!(name, root)} end)
    end
  end

  @spec configure_credentials!(String.t()) :: %__MODULE__{} | no_return
  defp configure_credentials!(root) do
    File.mkdir_p!(root)
    File.chmod(root, 0o700)
    credentials = generate()
    write_credentials!(root, credentials)
  end

  @spec read_private_credentials!(String.t()) :: %__MODULE__{} | no_return()
  defp read_private_credentials!(root) do
    priv_key = read_data_checksum!(Path.join(root, @private_key))
    pub_key = read_data_checksum!(Path.join(root, @public_key))
    id = read_data_checksum!(Path.join(root, @carrier_id))
    %__MODULE__{private: priv_key, public: pub_key, id: id}
  end

  @spec scan(String.t()) :: [] | [String.t()]
  defp scan(root) do
    names = Path.wildcard(Path.join(root, "*.id"))
    names
    |> Enum.map(fn(name) -> Path.rootname(Path.basename(name)) end)
    |> Enum.filter(fn(name) -> name != "carrier" end)
  end

  @spec read_data_checksum!(String.t()) :: binary() | no_return()
  defp read_data_checksum!(path) do
    stat = File.stat!(path)
    if stat.size < @key_hash_size + 32 do
      raise SecurityError.new("Credential file #{path} is corrupted. Please generate a new credential set.")
    end
    ensure_correct_mode!(path, 0o100600)
    raw_data = File.read!(path)
    case verify_data_checksum(raw_data) do
      :error ->
        raise SecurityError.new("Credential file #{path} is corrupted. Please generate a new credential set.")
      key ->
        key
    end
  end

  @spec verify_data_checksum(binary()) :: binary() | :error
  defp verify_data_checksum(raw_data) do
    <<hash::binary-size(@key_hash_size), data::binary>> = raw_data
    if :enacl.hash(data) == hash do
      data
    else
      :error
    end
  end

  @spec write_credentials!(String.t(), %__MODULE__{}) :: %__MODULE__{} | no_return()
  defp write_credentials!(root, credentials) do
    write_data_checksum!(credentials.public, Path.join(root, @public_key))
    write_data_checksum!(credentials.private, Path.join(root, @private_key))
    write_data_checksum!(credentials.id, Path.join(root, @carrier_id))
    credentials
  end

  @spec write_data_checksum!(binary(), String.t()) :: String.t() | no_return()
  defp write_data_checksum!(data, path) do
    contents = :erlang.list_to_binary([:enacl.hash(data), data])
    File.write!(path, contents)
    File.chmod!(path, 0o600)
    path
  end

  @spec ensure_correct_mode!(String.t(), pos_integer()) :: true | no_return()
  defp ensure_correct_mode!(path, path_mode) do
    stat = File.stat!(path)
    mode = Util.convert_integer(stat.mode, 8)
    if mode != path_mode do
      raise SecurityError.new("Path #{path} should have mode #{Integer.to_string(path_mode, 8)} " <>
        "but has #{Integer.to_string(mode, 8)} instead")
    else
      true
    end
  end

  @spec read_public_credential!(String.t(), String.t()) :: Keyword.t() | no_return()
  defp read_public_credential!(name, path) do
    pub_key = read_data_checksum!(Path.join(path, creds_file_name(name, :public)))
    id = read_data_checksum!(Path.join(path, creds_file_name(name, :id)))
    %__MODULE__{public: pub_key, id: id}
  end

  @spec creds_file_name(String.t(), atom()) :: String.t()
  defp creds_file_name(name, :private) do
    "#{name}_priv.key"
  end
  defp creds_file_name(name, :public) do
    "#{name}_pub.key"
  end
  defp creds_file_name(name, :id) do
    "#{name}.id"
  end
end
