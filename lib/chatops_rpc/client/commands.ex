defmodule ChatopsRPC.Client.Commands do
  @moduledoc false
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  def list_rpcs(server, prefix) do
    case :ets.lookup(server, prefix) do
      [{^prefix, rpcs}] ->
        rpcs

      [] ->
        []
    end
  end

  def update_rpcs(server, prefix, rpcs) do
    GenServer.call(server, {:update, prefix, rpcs})
  end

  def init(opts) do
    tab = :ets.new(opts[:name], [:named_table, :protected, :set])

    state = %{
      table: tab
    }

    {:ok, state}
  end

  def handle_call({:update, prefix, rpcs}, _, state) do
    true = :ets.insert(state.table, {prefix, rpcs})
    {:reply, :ok, state}
  end
end
