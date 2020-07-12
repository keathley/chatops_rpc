defmodule ChatopsRPC.PlugTest do
  use ExUnit.Case, async: false

  alias ChatopsRPC.TestServer

  setup_all do
    TestServer.start()

    :ok
  end

  setup do
    start_supervised({Finch, name: Test})

    :ok
  end

  test "requires a valid timestamp" do
    url = "http://localhost:4002/_chatops"
    now = DateTime.add(DateTime.utc_now(), -90, :second)
    ts = DateTime.to_iso8601(now)
    headers = [
      {"Chatops-Timestamp", ts},
    ]

    {:ok, resp} = Finch.request(Finch.build(:get, url, headers), Test)
    decoded = Jason.decode!(resp.body)
    assert decoded["error"] == "Chatops timestamp must be within 1 minute of server time"
  end

  test "requires a valid nonce" do
    url   = "http://localhost:4002/_chatops"
    now   = DateTime.utc_now()
    ts    = DateTime.to_iso8601(now)

    headers = [
      {"Chatops-Timestamp", ts},
    ]

    {:ok, resp} = Finch.request(Finch.build(:get, url, headers), Test)
    decoded = Jason.decode!(resp.body)
    assert decoded["error"] == "Chatops-Nonce header is required"
  end

  test "nonces cannot be reused" do
    url   = "http://localhost:4002/_chatops"
    now   = DateTime.utc_now()
    ts    = DateTime.to_iso8601(now)
    nonce = Base.encode64(:crypto.strong_rand_bytes(32))

    headers = [
      {"Chatops-Timestamp", ts},
      {"Chatops-Nonce", nonce},
    ]

    {:ok, _resp} = Finch.request(Finch.build(:get, url, headers), Test)
    {:ok, resp} = Finch.request(Finch.build(:get, url, headers), Test)
    decoded = Jason.decode!(resp.body)
    assert decoded["error"] == "Nonces cannot be re-used"
  end

  @tag :skip
  test "includes a signature header" do
    flunk "Not tested yet"
    flunk "Invalid signature"
    flunk "Errors if invalid signature"
  end
end
