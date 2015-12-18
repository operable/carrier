defmodule Carrier.Signature do

  alias Carrier.Credentials
  alias Carrier.CredentialManager
  alias Carrier.Util


  def sign(str) when is_binary(str),
    do: sign(Poison.decode!(str))

  @doc "Signs a JSON object using the system credentials"
  @spec sign(Map.t()) :: Map.t() | no_return()
  def sign(obj) do
    creds = CredentialManager.get()
    sign(obj, creds)
  end

  @doc "Signs a JSON object using `Carrier.Credentials`"
  @spec sign(Map.t(), Credentials.t()) :: Map.t() | no_return()
  def sign(obj, %Credentials{}=creds) when is_map(obj) do
    sign(obj, creds.private, creds.id)
  end

  @doc "Signs a JSON object"
  @spec sign(Map.t(), binary(), String.t()) :: Map.t() | no_return()
  def sign(obj, key, id) when is_map(obj) do
    text = mangle!(obj)
    sig = :enacl.sign_detached(text, key)
    sig = Util.binary_to_hex_string(sig)
    %{"data" => obj, "signature" => sig, "id" => id}
  end

  @doc "Verify JSON object signature"
  @spec verify(Map.t(), binary()) :: boolean() | no_return()
  def verify(%{"data" => obj, "signature" => sig}, key) when is_map(obj) do
    sig = Util.hex_string_to_binary(sig)
    text = mangle!(obj)
    case :enacl.sign_verify_detached(sig, text, key) do
      {:ok, ^text} ->
        true
      _ ->
        false
    end
  end

  @spec extract_authenticated_payload(String.t) :: {:ok, String.t} | {:error, term}
  def extract_authenticated_payload(message) do
    envelope = Poison.decode!(message)
    id = envelope["id"]
    contents = envelope["data"]
    case Carrier.CredentialManager.get(id) do
      %Credentials{public: pub_key} ->
        case verify(envelope, pub_key) do
          true ->
            {:ok, Poison.encode!(contents)}
          false ->
            {:error, :not_verified}
        end
      nil ->
        {:error, {:unrecognized_id, id}}
    end
  end

  @spec mangle!(Map.t()) :: binary() | no_return()
  defp mangle!(obj) do
    # Message signatures can be thought of as a kind of checksum.
    # To eliminate any reliance on unspecified behaviors such as
    # hashtable ordering we sign a mangled version of the JSON text.
    Poison.encode!(obj)
    |> String.codepoints
    |> Enum.filter(fn(cp) -> String.match?(cp, ~r/(\s|\:|\"|{|})|[|]/) == false end)
    |> Enum.sort
    |> List.to_string
  end

end
