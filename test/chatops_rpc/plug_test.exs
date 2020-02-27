defmodule ChatopsRPC.PlugTest do
  use ExUnit.Case, async: false

  alias ChatopsRPC.TestServer

  setup_all do
    TestServer.start()

    :ok
  end

  test "requires a valid timestamp" do
    url = "http://localhost:4002/_chatops"
    now = DateTime.add(DateTime.utc_now(), -90, :second)
    ts = DateTime.to_iso8601(now)
    headers = [
      {"Chatops-Timestamp", ts},
    ]

    {:ok, resp} = Mojito.get(url, headers)
    decoded = Jason.decode!(resp.body)
    assert decoded["error"] == "Chatops timestamp must be within 1 minute of server time"
  end

  test "requires a valid nonce" do
    flunk "Not Tested yet"
    flunk "validate rejects duplicate nonces"
  end

  test "validate signature" do
    flunk "Not tested yet"
    flunk "Invalid signature"
    flunk "works with either private key"
    flunk "Errors if invalid signature"
  end
end
