defmodule ChatopsRPC.ClientTest do
  use ExUnit.Case, async: false

  alias ChatopsRPC.TestServer
  alias ChatopsRPC.Client

  setup_all do
    TestServer.start()

    :ok
  end

  test "can request rpcs from an endpoint" do
    url = "http://localhost:4002/_chatops"
    {:ok, response} = ChatopsRPC.listing(url)

    assert response == %{
      namespace: "test_ops",
      help: nil,
      error_response: nil,
      methods: %{
        "echo" => %{
          regex: "(?<text>.*)?",
          path: "echo",
          params: [],
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
    {:ok, response} = Client.call(url, "echo", rpc)
    assert response == "foo"
  end
end
