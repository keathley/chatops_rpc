defmodule ChatopsRPC.Client do
  @moduledoc """
  Provides the neccessary client processes for signing requests, listing
  known services, and polling endpoints for changes.
  """
  use Supervisor

  alias ChatopsRPC.Client.{
    Store,
    API,
  }

  defdelegate debug(server, url), to: Store
  defdelegate call(server, url, path, data), to: Store
  defdelegate poll(server, url, prefix), to: Store
  defdelegate remove(server, url), to: Store
  defdelegate list(server), to: Store
  # defdelegate private_key(server), to: Store

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(opts) do
    children = [
      {Store, opts},
      {API, opts},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
