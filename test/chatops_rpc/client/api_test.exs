defmodule ChatopsRPC.Client.APITest do
  use ExUnit.Case, async: false

  alias ChatopsRPC.TestServer
  alias ChatopsRPC.Client
  alias ChatopsRPC.Client.API

  setup_all do
    key = File.read!("test/support/chatops.key")
    Client.start_link(private_key: key)
    TestServer.start()

    :ok
  end

  test "can request rpcs from an endpoint" do
    url = "http://localhost:4002/_chatops"
    {:ok, response} = API.listing(Client, url)

    assert response == %{
      namespace: "test_ops",
      help: nil,
      error_response: nil,
      methods: %{
        "echo" => %{
          regex: "echo (?<text>.*)?",
          path: "echo",
          params: ["text"],
          help: "<text> - Echo some text back to you",
        }
      }
    }
  end

  test "can call rpcs" do
    url = "http://localhost:4002/_chatops"
    rpc = %{
      user: "chris",
      room_id: "room id",
      method: "echo",
      params: %{
        "text" => "foo"
      }
    }
    {:ok, response} = API.call(Client, url, "echo", rpc)
    assert response == "foo"
  end
end
