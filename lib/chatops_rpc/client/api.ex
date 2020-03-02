defmodule ChatopsRPC.Client.API do
  @moduledoc false
  alias ChatopsRPC.Client

  def listing(client, url) do
    with {:ok, %{body: body}} <- Mojito.get(url, headers(client, url)),
         {:ok, listing} <- Jason.decode(body),
         {:ok, cast} <- cast(listing) do
      {:ok, cast}
    end
  end

  def call(client, url, method, rpc) do
    url = "#{url}/#{method}"
    bin = Jason.encode!(rpc)
    headers = headers(client, url, bin)

    with {:ok, %{body: body}} <- Mojito.post(url, headers, bin),
         {:ok, resp} <- Jason.decode(body) do
      if resp["result"] do
        {:ok, resp["result"]}
      end
    end
  end

  def headers(client, url, body \\ "") do
    sk = Client.private_key(client)
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

