defmodule Carrier.CredentialManager do

  use GenServer
  use Adz

  alias Carrier.Credentials

  def start_link() do
    GenServer.start_link(__MODULE__, name: __MODULE__)
  end

  def get(name \\ :system) do
    case :ets.lookup(storage(), name) do
      [{_, creds}] ->
        creds
      _ ->
        nil
    end
  end

  def store!(%Credentials{}=creds) do
    credentials_path = Application.get_env(:carrier, :credentials_dir)
    Credentials.write_public_credentials!(credentials_path, creds)
    :ets.insert(storage(), {creds.id, creds})
  end

  def init(_) do
    try do
      credentials = Credentials.validate_files!
      init_credential_store(credentials)
      load_all_credentials()
      ready({:ok, nil})
    rescue
      e in [Carrier.SecurityError] ->
        Logger.error("#{e.message}")
        :init.stop()
    end
  end

  defp init_credential_store(creds) do
    :ets.new(storage(), [:set, :protected, :named_table, {:read_concurrency, true}])
    :ets.insert_new(storage(), {:system, creds.id})
    :ets.insert_new(storage(), {creds.id, creds})
  end

  defp load_all_credentials() do
    credentials_path = Application.get_env(:carrier, :credentials_dir)
    for {name, credential} <- Credentials.read_all_credentials!(credentials_path) do
      if name != "carrier" do
        :ets.insert_new(storage(), {name, credential})
        Logger.info("Loaded credentials for #{name}")
      end
    end
  end

  defp storage() do
    :carrier_creds
  end

end
