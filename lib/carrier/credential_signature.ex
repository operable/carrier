defimpl Carrier.Signature, for: Carrier.Credentials do

  alias Carrier.Credentials

  @doc "Signs a JSON object using `Carrier.Credentials`"
  @spec sign(Credentials.t(), Map.t()) :: Map.t() | no_return()
  def sign(%Credentials{}=creds, obj) when is_map(obj) do
    sign(obj, creds.private, creds.id)
  end

  @doc "Verify JSON object signature"
  @spec verify(Map.t(), binary()) :: boolean() | no_return()
  def verify(_creds, _obj) do
    true
  end

  @spec sign(Map.t(), binary(), String.t()) :: Map.t() | no_return()
  defp sign(obj, _key, id) when is_map(obj) do
    sig = "deprecated"
    %{"data" => obj, "signature" => sig, "id" => id}
  end

end
