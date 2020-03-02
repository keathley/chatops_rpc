defmodule ChatopsRPC.Client.Endpoints do
  @moduledoc false
  use GenServer

  alias ChatopsRPC.Client.API
  alias ChatopsRPC.Client.Listings

  require Logger

  def get_url(server, prefix) do
    GenServer.call(server, {:get_url, prefix})
  end

  def find_method(server, text) do
    GenServer.call(server, {:find_rpc, text})
  end

  def start_polling(server, url) do
    GenServer.call(server, {:put, url})
  end

  def list(server) do
    GenServer.call(server, :get_endpoints)
  end

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    name = Keyword.fetch!(opts, :name)

    data = %{
      client: opts[:client],
      name: name,
      listings: Listings.new()
    }

    {:ok, data}
  end

  def handle_call(:get_endpoints, _from, state) do
    {:reply, Listings.endpoints(state.listings), state}
  end

  def handle_call({:put, url}, _from, state) do
    # TODO - Make sure that the url / prefix don't already exist in here
    case API.listing(state.client, url) do
      {:ok, info} ->
        listings = Listings.add_listing(state.listings, info, url)
        {:reply, :ok, %{state | listings: listings}}

      {:error, e} ->
        {:reply, {:error, e}, state}
    end
  end

  def handle_call({:find_rpc, text}, _, state) do
    result = Listings.find_method(state.listings, text)
    {:reply, result, state}
  end

  def handle_info(:check_for_updates, state) do
    listings =
      state.listings
      |> Listings.endpoints
      |> Enum.reduce(state.listings, fn {prefix, url}, listings ->
        case API.listing(state.name, url) do
          {:ok, listing} ->
            Listings.update_listing(listings, prefix, listing)

          {:error, _e} ->
            Logger.error(fn -> "Error fetching listing from: #{url}" end)
            listings
        end
      end)

    schedule_check()
    {:noreply, %{state | listings: listings}}
  end

  defp schedule_check() do
    Process.send_after(self(), :check_for_updates, 10_000)
  end
end
