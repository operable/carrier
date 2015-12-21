defimpl Carrier.Signature, for: Carrier.Credentials do

  alias Carrier.Credentials
  alias Carrier.Util

  @doc "Signs a JSON object using `Carrier.Credentials`"
  @spec sign(Credentials.t(), Map.t()) :: Map.t() | no_return()
  def sign(%Credentials{}=creds, obj) when is_map(obj) do
    sign(obj, creds.private, creds.id)
  end

  @doc "Verify JSON object signature"
  @spec verify(Map.t(), binary()) :: boolean() | no_return()
  def verify(%Credentials{}=creds, %{"data" => obj, "signature" => sig}) when is_map(obj) do
    sig = Util.hex_string_to_binary(sig)
    text = mangle!(obj)
    case :enacl.sign_verify_detached(sig, text, creds.public) do
      {:ok, ^text} ->
        true
      _ ->
        false
    end
  end

  @spec mangle!(Map.t()) :: binary() | no_return()
  defp mangle!(obj) do
    # Message signatures can be thought of as a kind of checksum.
    # To eliminate any reliance on unspecified behaviors such as
    # hashtable ordering we sign a mangled version of the JSON text.
    Poison.encode!(obj)
    |> String.codepoints
    |> Enum.filter(fn(cp) -> String.match?(cp, ~r/\s/) == false end)
    |> Enum.sort
    |> List.to_string
  end

  @spec sign(Map.t(), binary(), String.t()) :: Map.t() | no_return()
  defp sign(obj, key, id) when is_map(obj) do
    text = mangle!(obj)
    sig = :enacl.sign_detached(text, key)
    sig = Util.binary_to_hex_string(sig)
    %{"data" => obj, "signature" => sig, "id" => id}
  end

end
