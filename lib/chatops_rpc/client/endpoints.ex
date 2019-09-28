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

  def start_polling(server, url, prefix) do
    GenServer.call(server, {:start_polling, url, prefix})
  end

  def remove(server, url) do
    GenServer.call(server, {:remove, url})
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

    schedule_check()
    {:ok, data}
  end

  def handle_call(:get_endpoints, _from, state) do
    {:reply, Listings.endpoints(state.listings), state}
  end

  def handle_call({:start_polling, url, prefix}, _from, state) do
    listing = Listings.listing(state.listings, prefix)

    if listing do
      {:error, "#{prefix} is already associated with #{listing.url}."}
    else
      case API.listing(state.client, url) do
        {:ok, info} ->
          listings = Listings.add_listing(state.listings, info, url, prefix)
          {:reply, :ok, %{state | listings: listings}}

        {:error, e} ->
          Logger.error(fn -> "Error adding chatops: #{inspect e}" end)
          {:reply, {:error, "calling #{url} failed."}, state}
      end
    end
  end

  def handle_call({:find_rpc, text}, _, state) do
    result = Listings.find_method(state.listings, text)
    {:reply, result, state}
  end

  def handle_call({:remove, url}, _, state) do
    listings = Listings.remove(state.listings, url)
    {:reply, :ok, %{state | listings: listings}}
  end

  def handle_info(:check_for_updates, state) do
    listings =
      state.listings
      |> Listings.endpoints
      |> Enum.reduce(state.listings, fn {prefix, endpoint}, listings ->
        case API.listing(state.client, endpoint.url) do
          {:ok, listing} ->
            Listings.update_listing(listings, prefix, listing)

          {:error, _e} ->
            Logger.error(fn -> "Error fetching listing from: #{endpoint.url}" end)
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
