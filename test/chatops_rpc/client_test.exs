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
    start_supervised({Client, private_key: key})

    :ok
  end

  test "can add endpoints" do
    assert :ok = Client.add("http://localhost:4002/_chatops", nil)

    list = Client.list()
    assert list["test_ops"].methods == [%{
      help: "echo <text> - Echo some text back to you",
      name: "echo",
      path: "echo",
      regex: ~r/^test_ops echo (?<text>.*)?/,
      params: ["text"],
    }]
  end

  @tag :skip
  test "won't add a service with a prefix that already exists" do
    flunk "Not tested yet"
  end

  @tag :skip
  test "adds help messages" do
    flunk "Not tested yet"
  end

  @tag :skip
  test "extracts arguments" do
    flunk "Not tested yet"
  end

  @tag :skip
  test "can add with a prefix" do
    flunk "not tested yet"
  end

  @tag :skip
  test "lists all prefixes + urls" do
    flunk "not tested yet"
  end

  @tag :skip
  test "can remove urls" do
    flunk "not tested yet"
  end

  @tag :skip
  test "recovers if the endpoint crashes" do
    flunk "Not tested yet"
  end
end
