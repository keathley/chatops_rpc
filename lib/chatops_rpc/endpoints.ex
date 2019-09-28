defmodule ChatopsRPC.Endpoints do
  use GenServer

  alias ChatopsRPC.Api

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

  def handle_info(:check_for_updates, data) do
    for {prefix, endpoint} <- data.endpoints do
      with {:ok, rpcs} <- Api.info(endpoint) do
        Storage.put(prefix, rpcs)
      end
    end

    schedule_check()
    {:noreply, data}
  end

  defp get(

  defp schedule_check() do
    Process.send_after(self(), :check_for_updates, 5_000)
  end

  defp server_name(name) do
    :"#{name}.Endpoints"
  end
end

