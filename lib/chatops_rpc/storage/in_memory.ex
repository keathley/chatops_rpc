defmodule ChatopsRPC.Storage.InMemory do
  @moduledoc """
  Provides in-memory storage. This memory is volatile and should only be used
  for testing, development, or other situations where you're comfortable losing
  data due to a restart or crash.
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(_opts) do
    {:ok, %{}}
  end
end

