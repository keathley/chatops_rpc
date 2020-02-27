defmodule ChatopsRPC.Client.Endpoints do
  use GenServer

  alias ChatopsRPC.Client.API
  alias ChatopsRPC.Client.Commands

  def put(server, url) do
    GenServer.call(server_name(server), {:put, url})
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
    tab = :ets.new(server_name(name), [:named_table, :protected, :set])

    data = %{
      name: name,
      table: tab,
      endpoints: %{},
      commands: opts[:commands],
    }

    {:ok, data}
  end

  def handle_call({:put, url}, _from, state) do
    # TODO - Make sure that the url / prefix don't already exist in here
    case API.info(state.name, url) do
      {:ok, info} ->
        :ok = Commands.update_rpcs(state.commands, info.namespace, info.methods)
        state = put_in(state, [:endpoints, info.namespace], url)
        {:reply, :ok, state}

      {:error, e} ->
        {:reply, {:error, e}, state}
    end
  end

  def handle_call(:get_urls, _from, data) do
    {:reply, data.endpoints, data}
  end

  def handle_info(:check_for_updates, data) do
    for {prefix, endpoint} <- data.endpoints do
      with {:ok, info} <- API.info(data.name, endpoint) do
        Commands.update_rpcs(data.commands, prefix, info.methods)
      end
    end

    schedule_check()
    {:noreply, data}
  end

  defp schedule_check() do
    Process.send_after(self(), :check_for_updates, 10_000)
  end

  defp server_name(name) do
    :"#{name}.Endpoints"
  end
end

