defmodule ChatopsRPC.Plug.BodyReader do
  @moduledoc """
  Custom body reader that stores the message body in plug private. This is required
  for chatops rpc to do authentication against the signing token provided by
  the client.

  ## Example
      plug Plug.Parsers,
        parsers: [:urlencoded],
        body_reader: {ChatopsRPC.Plug.BodyReader, :read_body, []}
  """

  alias Plug.Conn

  def read_body(conn, opts) do
    {:ok, body, conn} = Conn.read_body(conn, opts)
    {:ok, body, Conn.put_private(conn, :chatops_body, body)}
  end
end
