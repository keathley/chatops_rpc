defmodule ChatopsRPC.HandlerTest do
  use ExUnit.Case, async: false

  alias Fawkes.Adapter.TestAdapter
  alias ChatopsRPC.TestServer

  import TestAdapter

  setup_all do
    TestServer.start()

    {:ok, url: "http://localhost:4002/_chatops"}
  end

  setup do
    start_supervised({ChatopsRPC.TestBot, self()})

    :ok
  end

  test "won't add a service with a prefix that already exists", %{url: url} do
    chat(".rpc add #{url} --prefix test")
    assert_receive {:reply, msg}, 1_000
    assert msg == "Okay, I'll poll #{url} for chatops."

    chat(".rpc add http://keathley.io/_chatops --prefix test")
    assert_receive {:reply, msg}, 1_000
    assert msg == "Sorry, test is already associated with #{url}"
  end

  test "adds help messages", %{url: url} do
    chat(".rpc add #{url}")
    assert_receive {:reply, _}, 1_000

    chat(".test_ops")
    assert_receive {:code, help}, 500
    assert help == "echo <text> - Echo some text back to you"
  end

  test "lists prefixes", %{url: url} do
    chat(".rpc add #{url}")
    assert_receive {:reply, _}, 1_000

    chat(".rpc add #{url} --prefix foo")
    assert_receive {:reply, _}, 1_000

    chat(".rpc add #{url} --prefix bar")
    assert_receive {:reply, _}, 1_000

    chat(".rpc list")
    assert_receive {:code, msg}
    assert msg == """
    bar - #{url}
    foo - #{url}
    test_ops - #{url}
    """ |> String.trim_trailing
  end

  test "removes urls", %{url: url} do
    chat(".rpc add #{url}")
    assert_receive {:reply, _}

    chat(".rpc remove #{url}")
    assert_receive {:reply, msg}, 1_000
    assert msg == "Ok, I won't poll or run commands from http://localhost:4002/_chatops"
  end

  test "can call commands", %{url: url} do
    chat(".rpc add #{url} --prefix test")
    assert_receive {:reply, _}, 1_000

    chat(".test echo I'm causin' more family feuds than Richard Dawson")
    assert_receive {:say, "I'm causin' more family feuds than Richard Dawson"}, 1_000
  end

  @tag :skip
  test "allows arbitrary arguments", %{url: url} do
    chat(".rpc add #{url} --prefix test")
    assert_receive {:reply, _}, 1_000

    chat(".test echo foo --stuff abc")
    assert_receive {:say, "foo"}, 1_000
  end
end
