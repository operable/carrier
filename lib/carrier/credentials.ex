defmodule Carrier.Credentials do

  defstruct [:id, :tag]

  @cred_db "carrier_credentials.db"
  @carrier_id "carrier.id"

  @doc "Generates a new private/public keypair"
  @spec generate() :: %__MODULE__{}
  def generate() do
    %__MODULE__{id: UUID.uuid4()}
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
