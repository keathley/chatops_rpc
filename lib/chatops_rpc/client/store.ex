defmodule ChatopsRPC.Client.Store do
  @moduledoc false
  use GenServer

  require Logger

  alias ChatopsRPC.Client.API
  alias ChatopsRPC.Client.Listings

  def start_link(opts) do
    opts = Keyword.merge([name: ChatopsRPC.Client], opts)
    GenServer.start_link(__MODULE__, opts, name: opts[:name])
  end

  def debug(server, url) do
    sk = private_key(server)
    API.listing(url, sk)
  end

  def call(server \\ __MODULE__, url, path, data) do
    sk = private_key(server)
    API.call(url, path, data, sk)
  end

  def poll(server, url, prefix) do
    GenServer.call(server, {:add, url, prefix})
  end

  def remove(server, url) do
    GenServer.call(server, {:remove, url})
  end

  def list(server) do
    GenServer.call(server, :list)
  end

  defp private_key(name) do
    :persistent_term.get({name, :private_key})
  end

  def init(opts) do
    name = Keyword.fetch!(opts, :name)
    sk = load_private_key!(opts)
    :persistent_term.put({name, :private_key}, sk)

    data = %{
      name: name,
      listings: Listings.new()
    }

    schedule_check()
    {:ok, data}
  end

  def handle_call(:list, _from, state) do
    {:reply, Listings.endpoints(state.listings), state}
  end

  def handle_call({:add, url, prefix}, _from, state) do
    case API.listing(url, private_key(state.name)) do
      {:ok, info} ->
        listings = Listings.add_listing(state.listings, info, url, prefix)
        {:reply, :ok, %{state | listings: listings}}

      {:error, e} ->
        Logger.error(fn -> "Error adding chatops: #{inspect e}" end)
        listings = Listings.add_listing(state.listings, %{}, url, prefix)
        {:reply, :ok, %{state | listings: listings}}
    end
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
        case API.listing(endpoint.url, private_key(state.name)) do
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

  defp load_private_key!(opts) do
    case opts[:private_key] do
      nil ->
        raise ArgumentError, "chatops client requires a `:private_key`"

      contents ->
        [entry] = :public_key.pem_decode(contents)
        :public_key.pem_entry_decode(entry)
    end
  end
end
