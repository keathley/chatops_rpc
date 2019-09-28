defmodule ChatopsRPC.Client.Listings do
  @moduledoc false

  def new do
    %{endpoints: %{}}
  end

  def listing(%{endpoints: endpoints}, prefix) do
    Map.get(endpoints, prefix)
  end

  def endpoints(%{endpoints: endpoints}) do
    endpoints
  end

  def remove(%{endpoints: endpoints}, url) do
    endpoints =
      endpoints
      |> Enum.reject(fn {_prefix, endpoint} -> endpoint.url == url end)
      |> Enum.into(%{})

    %{endpoints: endpoints}
  end

  def add_listing(listings, info, url, prefix) do
    namespace = prefix || info.namespace
    methods =
      info.methods
      |> Enum.map(fn {name, method} -> Map.put(method, :name, name) end)
      |> Enum.map(fn method ->
        case Regex.compile("^#{namespace} #{method.regex}") do
          {:ok, regex} ->
            %{method | regex: regex}

          {:error, _e} ->
            false
        end
      end)
      |> Enum.filter(& &1)

    endpoint = %{
      url: url,
      help: info.help,
      methods: methods,
    }
    endpoints = Map.put(listings.endpoints, namespace, endpoint)

    %{listings | endpoints: endpoints}
  end

  def update_listing(listings, prefix, listing) do
    methods =
      listing.methods
      |> Enum.map(fn {name, method} -> Map.put(method, :name, name) end)
      |> Enum.map(fn method ->
        case Regex.compile("^#{prefix} #{method.regex}") do
          {:ok, regex} ->
            %{method | regex: regex}

          {:error, _e} ->
            false
        end
      end)
      |> Enum.filter(& &1)

    listings
    |> put_in([:endpoints, prefix, :methods], methods)
    |> put_in([:endpoints, prefix, :help], listing.help)
  end

  def find_method(%{endpoints: endpoints}, text) do
    Enum.find_value(endpoints, fn {_prefix, info} ->
      method = Enum.find(info.methods, fn method ->
        Regex.match?(method.regex, text)
      end)

      if method do
        {info.url, method}
      else
        false
      end
    end)
  end
end
