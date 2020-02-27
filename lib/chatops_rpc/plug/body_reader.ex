defmodule ChatopsRPC.Plug.BodyReader do
  @moduledoc """
  Custom [Plug.Parsers](https://hexdocs.pm/plug/Plug.Parsers.html#module-custom-body-reader) body
  reader to support the custom `Slash.Signature` verification process.
  ***This must be configured for your application when using Slash!***
  ## Example
      plug Plug.Parsers,
        parsers: [:urlencoded],
        body_reader: {Slash.BodyReader, :read_body, []}
  """

  alias Plug.Conn

  def read_body(conn, opts) do
    {:ok, body, conn} = Conn.read_body(conn, opts)
    {:ok, body, Conn.put_private(conn, :chatops_body, body)}
  end
end
