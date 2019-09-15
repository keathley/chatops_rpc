defmodule ChatopsRPC.Endpoints do
  use GenServer

  def put(server, prefix, url) do
    GenServer.call(server_name(server), {:put, prefix, url})
  end

  def get_all_urls(server) do
    GenServer.call(server_name(server), :get_urls)
  end

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: server_name(name))
  end

  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    tab = :ets.new(server_name(name), [:named_table, :public, :set])

    data = %{
      name: name,
      table: tab,
      endpoints: %{}
    }

    {:ok, data}
  end

  def handle_call({:put, prefix, url}, _from, data) do
    case get_in(data, [:endpoints, prefix]) do
      nil ->
        data = put_in(data, [:endpoints, prefix], url)
        {:reply, :ok, data}

      ^url ->
        {:reply, :ok, data}

      other_url ->
        {:reply, {:error, {:existing_prefix, other_url}}, data}
    end
  end

  def handle_call(:get_urls, _from, data) do
    {:reply, data.endpoints, data}
  end

  defp server_name(name) do
    :"#{name}.Endpoints"
  end
end

