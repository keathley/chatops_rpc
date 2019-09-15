defmodule ChatopsRPCTest do
  use ExUnit.Case

  alias ChatopsRPC.Storage.InMemory

  describe "start_link/1" do
    test "starts a chatopsrpc supervision tree" do
      ChatopsRPC.start_link(name: TestOps, storage: InMemory)
    end
  end

  describe "add_endpoint" do
    setup do
      ChatopsRPC.start_link(name: TestOps, storage: InMemory)

      :ok
    end

    test "only allows https endpoints" do
      url = "http://localhost:4000/_chatops"
      {:error, _} = ChatopsRPC.add_endpoint(TestOps, "test", url)
    end

    test "adds the endpoint to the list of checked endpoints" do
      url = "https://localhost:4000/_chatops"
      :ok = ChatopsRPC.add_endpoint(TestOps, "test", url)
      assert ChatopsRPC.list_endpoints(TestOps) == %{"test" => url}
    end

    test "adding the same endpoint is idempotent" do
      url = "https://localhost:4000/_chatops"
      assert :ok = ChatopsRPC.add_endpoint(TestOps, "test", url)
      assert :ok = ChatopsRPC.add_endpoint(TestOps, "test", url)
    end

    test "adding a different url with the same prefix is an error" do
      url_1 = "https://localhost:4000/_chatops"
      url_2 = "https://remotehost:4000/_chatops"

      assert :ok = ChatopsRPC.add_endpoint(TestOps, "test", url_1)
      assert {:error, {:existing_prefix, url_1}} == ChatopsRPC.add_endpoint(TestOps, "test", url_2)
    end
  end
end
