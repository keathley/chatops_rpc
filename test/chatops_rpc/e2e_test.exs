defmodule ChatopsRPC.E2ETest do
  use ExUnit.Case, async: false

  alias ChatopsRPC.TestServer

  setup_all do
    TestServer.start()

    :ok
  end

  test "can request rpcs from an endpoint" do
    url = "http://localhost:4002/_chatops"
    assert ChatopsRPC.fetch_rpcs(url) == []
  end
end
