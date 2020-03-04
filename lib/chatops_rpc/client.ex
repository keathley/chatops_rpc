defmodule ChatopsRPC.Client do
  @moduledoc """
  Provides the neccessary client processes for signing requests, listing
  known services, and polling endpoints for changes.
  """
  use Supervisor

  alias ChatopsRPC.Client.{
    API,
    Endpoints,
  }

  def add(server \\ __MODULE__, url, prefix) do
    Endpoints.start_polling(endpoints_name(server), url, prefix)
  end

  def remove(server, url) do
    Endpoints.remove(endpoints_name(server), url)
  end

  def call(server \\ __MODULE__, url, path, data) do
    API.call(server, url, path, data)
  end

  def list(server \\ __MODULE__) do
    Endpoints.list(endpoints_name(server))
  end

  def methods(server \\ __MODULE__) do
    endpoints_name(server)
    |> Endpoints.list()
    |> Enum.flat_map(fn {_prefix, info} ->
      Enum.map(info.methods, fn m -> Map.put(m, :url, info.url) end)
    end)
  end

  # def find_method(server \\ __MODULE__, text, cb) do
  #   case Endpoints.find_method(endpoints_name(server), text) do
  #     nil ->
  #       nil

  #     {url, method} ->
  #       cb.(url, method)
  #   end
  # end

  def private_key(server) do
    :persistent_term.get({server, :private_key})
  end

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, opts, name: opts[:name])
  end

  def init(opts) do
    load_private_key!(opts)

    children = [
      {Endpoints, [name: endpoints_name(opts[:name]), client: opts[:name]]},
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  defp endpoints_name(name) do
    :"#{name}.Endpoints"
  end

  defp load_private_key!(opts) do
    case opts[:private_key] do
      nil ->
        raise ArgumentError, "chatops client requires a `:private_key`"

      contents ->
        [entry] = :public_key.pem_decode(contents)
        key = :public_key.pem_entry_decode(entry)
        :persistent_term.put({opts[:name], :private_key}, key)
    end
  end
end
