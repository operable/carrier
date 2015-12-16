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

  def init(_) do
    try do
      credentials = Credentials.validate_files!
      store_credentials(credentials)
      ready({:ok, nil})
    rescue
      e in [Carrier.SecurityError] ->
        Logger.error("#{e.message}")
        :init.stop()
    end
  end

  defp store_credentials(creds) do
    :ets.new(storage(), [:set, :protected, :named_table, {:read_concurrency, true}])
    :ets.insert_new(storage(), {:system, creds})
  end

  defp storage() do
    :carrier_creds
  end

end
