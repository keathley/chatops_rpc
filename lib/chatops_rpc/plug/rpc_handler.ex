defmodule ChatopsRPC.Plug.RPCHandler do
  @moduledoc false

  def call(conn, opts) do
  end

  defp list(conn) do
    methods =
      @commands
      # unquote(commands)
      |> Enum.map(fn {name, rpc} -> {name, Map.take(rpc, [:path, :params, :regex, :help])} end)
      |> Enum.into(%{})

    body = Jason.encode!(%{
      namespace: @namespace,
      help: nil,
      error_response: nil,
      methods: methods
    })

    conn
    |> Plug.Conn.put_resp_header("content-type", "application/json")
    |> Plug.Conn.send_resp(200, body)
    |> Plug.Conn.halt()
  end
end
