defmodule ChatopsRPC.Client.Listings do
  def new do
    %{endpoints: %{}}
  end

  def endpoints(%{endpoints: endpoints}) do
    endpoints
  end

  def add_listing(listings, info, url) do
    methods =
      info.methods
      |> Enum.map(fn {name, method} -> Map.put(method, :name, name) end)
      |> Enum.map(fn method ->
        case Regex.compile("^#{info.namespace} #{method.regex}") do
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
    endpoints = Map.put(listings.endpoints, info.namespace, endpoint)

    %{listings | endpoints: endpoints}
  end

  def update_listing(listings, prefix, listing) do
    put_in(listings, [:endpoints, prefix], listing)
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
