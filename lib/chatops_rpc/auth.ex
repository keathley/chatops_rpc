defmodule ChatopsRPC.Auth do
  @moduledoc """
  Generates and validates authentication headers
  """

  def headers(url, body) do
    nonce = Base.encode64(:crypto.strong_rand_bytes(32))
    timestamp = DateTime.to_iso8601(DateTime.utc_now())
    signature = :public_key.sign("#{url}\n#{nonce}\n#{timestamp}\n#{body}", :sha256, pk())
  end

  def pk do
    raw = File.read!("priv/chatops.key")
    [entry] = :public_key.pem_decode(raw)
    pk = :public_key.pem_entry_decode(entry)
  end
end

