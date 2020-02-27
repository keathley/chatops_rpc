defmodule ChatopsRPC.Server do
  use GenServer

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  def base_url(server \\ __MODULE__) do
    GenServer.call(server, :get_base_url)
  end

  def public_key(server) do
    [{:public_key, key}] = :ets.lookup(server, :public_key)
    key
  end

  def alt_public_key(server) do
    case :ets.lookup(server, :alt_public_key) do
      [{_, key}] ->
        key

      [] ->
        nil
    end
  end

  def store_nonce(server \\ __MODULE__, nonce) do
    GenServer.call(server, {:store_nonce, nonce})
  end

  def init(opts) do
    tab = :ets.new(opts[:name], [:named_table, :protected, :bag])
    base_url = opts[:base_url] || raise ArgumentError, "chatops server requires a base_url"

    public_key = case opts[:public_key] do
      nil -> raise ArgumentError, "chatops server requires a public key"
      contents -> decode_key(contents)
    end

    alt_public_key = case opts[:alt_public_key] do
      nil -> nil
      contents -> decode_key(contents)
    end

    :ets.insert(tab, [{:public_key, public_key}, {:alt_public_key, alt_public_key}])

    state = %{
      base_url: base_url,
      tab: tab,
      public_key: public_key,
      alt_public_key: alt_public_key,
    }
    {:ok, state}
  end

  def handle_call(:get_base_url, _from, state) do
    {:reply, state.base_url, state}
  end

  def handle_call({:store_nonce, nonce}, _from, state) do
    case :ets.match(state.tab, {:nonces, nonce}) do
      [] ->
        :ets.insert(state.tab, {:nonces, nonce})
        {:reply, :ok, state}

      [_] ->
        {:reply, :taken, state}
    end
  end

  defp decode_key(key) do
    [entry] = :public_key.pem_decode(key)
    :public_key.pem_entry_decode(entry)
  end
end
