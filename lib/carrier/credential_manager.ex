defmodule Carrier.CredentialManager do

  defstruct [:store]

  use GenServer
  use Adz

  alias Carrier.Signature
  alias Carrier.Credentials
  alias Carrier.CredentialStore

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get() do
    get(:system, by: :tag)
  end

  def get(value, opts) when opts == [by: :id] or opts == [by: :tag] do
    GenServer.call(__MODULE__, {:get, value, opts}, :infinity)
  end

  def store(%Credentials{}=creds) do
    GenServer.call(__MODULE__, {:store, creds}, :infinity)
  end

  def sign_message(message) when is_map(message) do
    {:ok, creds} = get()
    Signature.sign(creds, message)
  end

  def verify_signed_message(%{"id" => id, "data" => obj}=message) do
    case get(id, by: :id) do
      {:ok, nil} ->
        false
      {:ok, creds} ->
        if Signature.verify(creds, message) do
          {true, obj}
        else
          false
        end
    end
  end

  def init(_) do
    case Application.get_env(:carrier, :credentials_dir) do
      nil ->
        Logger.error("Configuration entry :carrier -> :credentials_dir is empty. Aborting startup.")
        :init.stop()
      root ->
        try do
          store_path = CredentialStore.validate!(root)
          {:ok, db} = CredentialStore.open(store_path)
          ready({:ok, %__MODULE__{store: db}})
        rescue
          e in [Carrier.SecurityError, Carrier.FileError] ->
            Logger.error("#{e.message}")
            :init.stop()
        end
    end
  end

  def handle_call({:get, value, opts}, _from, %__MODULE__{store: db}=state) do
    {:reply, CredentialStore.lookup(db, value, opts), state}
  end
  def handle_call({:store, creds}, _from, %__MODULE__{store: db}) do
    {:reply, CredentialStore.store(db, creds)}
  end
  def handle_call(_ignored, _from, state) do
    {:reply, :ignored, state}
  end

end
