defmodule ChatopsRPC.Client do
  @moduledoc false

  def list_rpcs(url) do
    with {:ok, %{body: body}} <- Mojito.get(url, headers(url)),
         {:ok, listing} <- Jason.decode(body),
         {:ok, cast} <- cast(listing) do
      {:ok, cast}
    end
  end

  def call(url, method, rpc) do
    url = "#{url}/#{method}"
    bin = Jason.encode!(rpc)
    headers = headers(url, bin)

    with {:ok, %{body: body}} <- Mojito.post(url, headers, bin),
         {:ok, resp} <- Jason.decode(body) do
      if resp["result"] do
        {:ok, resp["result"]}
      end
    end
  end

  def headers(url, body \\ "") do
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
      |> :public_key.sign(:sha256, pk())
      |> Base.encode64
    signature_header = "Signature keyid=hedwigkey,signature=#{signature}"

    [
      {"Chatops-Nonce", nonce},
      {"Chatops-Timestamp", timestamp},
      {"Chatops-Signature", signature_header},
      {"Content-type", "application/json"},
      {"Accept", "application/json"},
    ]
  end

  defp nonce do
    Base.encode64(:crypto.strong_rand_bytes(32))
  end

  def pk do
    raw = File.read!("priv/chatops.key")
    [entry] = :public_key.pem_decode(raw)
    pk = :public_key.pem_entry_decode(entry)
  end

  defp cast(listing) do
    methods =
      listing["methods"]
      |> Enum.map(fn {name, rpc} ->
        rpc = %{
          regex: rpc["regex"],
          path: rpc["path"],
          params: rpc["params"],
          help: rpc["help"],
        }
        {name, rpc}
      end)
      |> Enum.into(%{})

    listing = %{
      namespace: listing["namespace"],
      help: listing["help"],
      error_response: listing["error_response"],
      methods: %{
        "echo" => %{
          regex: "(?<text>.*)?",
          path: "echo",
          params: [],
          help: "<text> - Echo some text back to you",
        }
      }
    }

    {:ok, listing}
  end
end

