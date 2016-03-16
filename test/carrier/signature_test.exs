defmodule Carrier.SignatureTest do

  alias Carrier.Signature

  use Carrier.Test.Hygiene

  setup_all do
    {:ok, %{creds: Carrier.Credentials.generate(),
            other_creds: Carrier.Credentials.generate()}}
  end

  defmacrop verify_signature_envelope(signed, original, creds) do
    quote bind_quoted: [signed: signed, original: original, creds: creds], location: :keep do
      assert signed != original
      assert signed["data"] == original
      assert is_binary(signed["signature"])
      assert signed["id"] == creds.id
    end
  end

  test "signing maps (JSON objects)", context do
    obj = %{first_name: "Bob", last_name: "Bobbington"}
    signed = Signature.sign(context.creds, obj)
    verify_signature_envelope(signed, obj, context.creds)
  end

  test "verifying signed JSON objects", context do
    obj = %{first_name: "Bob", last_name: "Bobbington"}
    signed = Signature.sign(context.creds, obj)
    verify_signature_envelope(signed, obj, context.creds)
    assert Signature.verify(context.creds, signed)
  end

end
