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

    assert :ok = Client.add("http://localhost:4002/_chatops")

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

  test "won't add a service with a prefix that already exists" do
    flunk "Not tested yet"
  end

  test "adds help messages" do
    flunk "Not tested yet"
  end

  test "extracts arguments" do
    flunk "Not tested yet"
  end

  test "can add with a prefix" do
    flunk "not tested yet"
  end

  test "lists all prefixes + urls" do
    flunk "not tested yet"
  end

  test "can remove urls" do
    flunk "not tested yet"
  end

  test "recovers if the endpoint crashes" do
    flunk "Not tested yet"
  end
end
