defmodule ChatopsRPC.Client.API do
  @moduledoc false

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
    }
  end

  def start_link(opts) do
    name = :"#{Keyword.get(opts, :name) || ChatopsRPC.Client}.API"
    Finch.start_link(name: name)
  end

  def listing(url, private_key) do
    request = Finch.build(:get, url, headers(url, "", private_key))

    with {:ok, %{body: body}} <- Finch.request(request, __MODULE__),
         {:ok, listing} <- Jason.decode(body),
         {:ok, cast} <- cast(listing) do
      {:ok, cast}
    end
  end

  def call(url, method, rpc, private_key) do
    url = "#{url}/#{method}"
    bin = Jason.encode!(rpc)
    headers = headers(url, bin, private_key)
    request = Finch.build(:post, url, headers, bin)

    with {:ok, %{body: body}} <- Finch.request(request, __MODULE__),
         {:ok, resp} <- Jason.decode(body) do
      cond do
        resp["result"] ->
          {:ok, resp["result"]}

        resp["error"] ->
          {:error, resp["error"]}
      end
    end
  end

  def headers(url, body, sk) do
    nonce     = Base.encode64(:crypto.strong_rand_bytes(32))
    timestamp = DateTime.to_iso8601(DateTime.utc_now())
    signature_string = """
    #{url}
    #{nonce}
    #{timestamp}
    #{body}
    """
    signature =
      signature_string
      |> :public_key.sign(:sha256, sk)
      |> Base.encode64

    signature_header = "Signature keyid=fawkes,signature=#{signature}"

    [
      {"Chatops-Nonce", nonce},
      {"Chatops-Timestamp", timestamp},
      {"Chatops-Signature", signature_header},
      {"Content-type", "application/json"},
      {"Accept", "application/json"},
    ]
  end

  defp cast(listing) do
    methods =
      listing["methods"]
      |> Enum.map(fn {name, rpc} ->
        {name, %{
          regex: rpc["regex"],
          path: rpc["path"],
          params: rpc["params"],
          help: rpc["help"],
        }}
      end)
      |> Enum.into(%{})

    listing = %{
      namespace: listing["namespace"],
      help: listing["help"],
      error_response: listing["error_response"],
      methods: methods,
    }

    {:ok, listing}
  end
end

