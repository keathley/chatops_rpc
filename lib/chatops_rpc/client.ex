defmodule ChatopsRPC.Client do
  @moduledoc false

  def call(url, req) do
    bin = Jason.encode!(req)
  end
end
