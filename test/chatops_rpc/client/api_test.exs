defmodule ChatopsRPC.Client.APITest do
  use ExUnit.Case, async: false

  alias ChatopsRPC.TestServer
  alias ChatopsRPC.Client.API

  setup_all do
    key = File.read!("test/support/chatops.key")
    [entry] = :public_key.pem_decode(key)
    pk1 = :public_key.pem_entry_decode(entry)

    key = File.read!("test/support/chatops.backup.key")
    [entry] = :public_key.pem_decode(key)
    pk2 = :public_key.pem_entry_decode(entry)

    TestServer.start()

    {:ok, pk: pk1, pk2: pk2}
  end

  setup do
    # start_supervised({ChatopsRPC.Client, []})
    start_supervised({ChatopsRPC.Client.API, []})

    :ok
  end

  test "can request rpcs from an endpoint", %{pk: pk} do
    url = "http://localhost:4002/_chatops"
    {:ok, response} = API.listing(url, pk)

    assert response == %{
      namespace: "test_ops",
      help: nil,
      error_response: nil,
      methods: %{
        "echo" => %{
          regex: "echo (?<text>.*)?",
          path: "echo",
          params: ["text"],
          help: "echo <text> - Echo some text back to you",
        }
      }
    }
  end

  test "can call rpcs", %{pk: pk} do
    url = "http://localhost:4002/_chatops"
    rpc = %{
      user: "chris",
      room_id: "room id",
      method: "echo",
      params: %{
        "text" => "foo"
      }
    }
    {:ok, response} = API.call(url, "echo", rpc, pk)
    assert response == "foo"
  end

  test "can use either private key", %{pk2: pk} do
    url = "http://localhost:4002/_chatops"
    rpc = %{
      user: "chris",
      room_id: "room id",
      method: "echo",
      params: %{
        "text" => "foo"
      }
    }
    {:ok, response} = API.call(url, "echo", rpc, pk)
    assert response == "foo"
  end
end
