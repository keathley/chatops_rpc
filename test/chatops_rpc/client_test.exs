defmodule ChatopsRPC.ClientTest do
  use ExUnit.Case, async: false

  alias ChatopsRPC.Client
  alias ChatopsRPC.TestServer

  setup_all do
    TestServer.start()

    :ok
  end

  setup do
    key = File.read!("test/support/chatops.key")
    Client.start_link(private_key: key)

    :ok
  end

  test "monitors endpoints" do
    us = self()

    assert :ok = Client.start_polling("http://localhost:4002/_chatops")

    Client.find_method("test_ops echo foo bar", fn url, method ->
      send(us, {:found, url, method})
    end)

    assert_receive {:found, url, method}
    assert url == "http://localhost:4002/_chatops"
    assert method.name == "echo"
  end

  test "can call methods" do
    us = self()
    assert :ok = Client.start_polling("http://localhost:4002/_chatops")

    Client.find_method("test_ops echo foo bar", fn url, method ->
      data = %{
        user: "test",
        room_id: "test-room",
        method: method.name,
        params: Regex.named_captures(method.regex, "test_ops echo foo bar")
      }
      {:ok, result} = Client.call(url, method.path, data)
      send(us, {:result, result})
    end)

    assert_receive {:result, text}
    assert text == "foo bar"
  end
end
