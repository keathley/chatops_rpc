defmodule ChatopsRPC.Server do
  use GenServer

  def start_link(opts) do
    name = opts[:name] || __MODULE__
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def base_url(server \\ __MODULE__) do
    GenServer.call(server, :get_base_url)
  end

  def init(opts) do
    base_url = opts[:base_url] || raise ArgumentError, "chatops server requires a base_url"

    state = %{
      base_url: base_url,
    }
    {:ok, state}
  end

  def handle_call(:get_base_url, _from, state) do
    {:reply, state.base_url, state}
  end
end
