defmodule Carrier.Credentials do

  defstruct [:id, :private, :public, :tag]

  @cred_db "carrier_credentials.db"
  @private_key "carrier_priv.key"
  @public_key "carrier_pub.key"
  @carrier_id "carrier.id"

  # 32 byte key w/64 byte checksum
  @key_hash_size 64

  @doc "Generates a new private/public keypair"
  @spec generate() :: %__MODULE__{}
  def generate() do
    keys = :enacl.sign_keypair()
    %__MODULE__{id: UUID.uuid4(), private: keys.secret, public: keys.public}
  end

  @doc "Adds a tag to credentials"
  @spec tag(%__MODULE__{}, atom()) :: %__MODULE__{}
  def tag(%__MODULE__{tag: nil}=credentials, tag) do
    %{credentials | tag: tag}
  end
  def tag(%__MODULE__{}=credentials, _tag) do
    credentials
  end

end
