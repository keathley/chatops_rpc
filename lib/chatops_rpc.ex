defmodule ChatopsRPC do
  @moduledoc """
  ChatopsRPC allows you specify chatops endpoints and send them rpc commands.
  """
  import Norm

  alias __MODULE__.{
    Endpoints,
    Supervisor
  }

  def child_spec(opts) do
    Supervisor.child_spec(opts)
  end

  def start_link(opts) do
    Supervisor.start_link(opts)
  end

  def add_endpoint(server, prefix, url) when is_binary(prefix) and is_binary(url) do
    with {:ok, url} <- conform(url, spec(valid_url())) do
      Endpoints.put(server, prefix, url)
    end
  end

  def list_endpoints(server) do
    Endpoints.get_all_urls(server)
  end

  def fetch_rpcs(url) do
  end

  def exec(prefix, rpc, args \\ []) do
  end

  def valid_url(url) do
    uri = URI.parse(url)

    !is_nil(uri.scheme) and uri.scheme == "https"
  end
end

