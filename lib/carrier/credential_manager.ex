defmodule Carrier.CredentialManager do

  use GenServer
  use Adz

  alias Carrier.Credentials

  @table :carrier_creds

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get() do
    get(:system)
  end

  def get(:system) do
    [{_, id}] = :ets.lookup(@table, :system)
    get(id)
  end
  def get(id) do
    case :ets.lookup(@table, id) do
      [{_, creds}] ->
        creds
      _ ->
        nil
    end
  end

  def store!(%Credentials{}=creds) do
    credentials_path = Application.get_env(:carrier, :credentials_dir)
    Credentials.write_public_credentials!(credentials_path, creds)
    GenServer.call(__MODULE__, {:store, creds})
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

  def handle_call({:store, creds}, _from, state) do
    true = :ets.insert(@table, {creds.id, creds})
    {:reply, :ok, state}
  end
  def handle_call(_message, _from, state) do
    {:reply, :ignored, state}
  end

  defp init_credential_store(creds) do
    :ets.new(@table, [:set, :protected, :named_table, {:read_concurrency, true}])
    :ets.insert_new(@table, {:system, creds.id})
    :ets.insert_new(@table, {creds.id, creds})
  end

  defp load_all_credentials() do
    credentials_path = Application.get_env(:carrier, :credentials_dir)
    for {name, credential} <- Credentials.read_all_credentials!(credentials_path) do
      if name != "carrier" do
        :ets.insert_new(@table, {name, credential})
        Logger.info("Loaded credentials for #{name}")
      end
    end
  end

end
