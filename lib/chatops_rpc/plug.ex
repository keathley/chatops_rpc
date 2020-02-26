defmodule ChatopsRPC.Plug do
  @moduledoc """
  Plug for adding chatops commands to your application.
  """
  @behaviour Plug

  import Plug.Conn

  def init(opts) do
    handler = Keyword.fetch!(opts, :handler)
    Code.ensure_loaded(handler)

    server = Keyword.get(opts, :server) || ChatopsRPC.Server

    %{handler: handler, server: server}
  end

  def call(conn, %{handler: handler, server: server}) do
    with :ok <- validate_url(conn, server),
         :ok <- validate_timestamp(conn),
         :ok <- validate_nonce(conn) do
         # :ok <- validate_headers(conn) do
         # :ok <- validate_signature(conn) do
      handle_request(conn, handler)
    else
      {:error, error} ->
        # TODO - Return the correct error here.
        conn
    end
  end

  # TODO - Ensure we're valid with all of our headers here
  def handle_request(%{method: "GET", path_info: []}=conn, handler) do
    methods =
      handler.commands()
      |> Enum.map(fn {name, command} -> {name, Map.take(command, [:path, :params, :regex, :help])} end)
      |> Enum.into(%{})

    body = Jason.encode!(%{
      namespace: handler.namespace(),
      help: nil,
      error_response: nil,
      methods: methods
    })

    conn
    |> Plug.Conn.put_resp_header("content-type", "application/json")
    |> Plug.Conn.send_resp(200, body)
    |> Plug.Conn.halt()
  end

  def handle_request(%{method: "POST", path_info: [path]}=conn, handler) do
    rpc = handler.commands()[path]

    command = %{
      method: conn.body_params["method"],
      params: conn.body_params["params"],
      user: conn.body_params["user"],
      room_id: conn.body_params["room_id"],
    }

    result = handler.dispatch_command(rpc.path, command)

    body = Jason.encode!(%{result: result})

    conn
    |> Plug.Conn.send_resp(201, body)
  end

  def handle_request(conn, _handler) do
    conn
    |> Plug.Conn.send_resp(404, "")
  end

  defp validate_url(conn, server) do
    url = ChatopsRPC.Server.base_url()

    if url == nil do
      raise ChatopsRPC.ConfigurationError, "You need to set the servers base_url to authenticate chatops rpcs"
    end

    :ok
  end

  defp validate_timestamp(conn) do
    case get_req_header(conn, "chatops-timestamp") do
      [ts] ->
        {:ok, ts, _} = DateTime.from_iso8601(ts)
        # Timestamp must be within 1 minute of our server time
        now = DateTime.utc_now()
        minute_ago = DateTime.add(now, -60, :second)
        minute_from_now = DateTime.add(now, 60, :second)
        if DateTime.compare(ts, minute_ago) == :gt && DateTime.compare(ts, minute_from_now) == :lt do
          :ok
        else
          {:error, "Chatops timestamp must be within 1 minute of server time"}
        end

      [] ->
        {:error, "Chatops timestamp was not provided"}
    end
  end

  defp validate_nonce(conn) do
  end
end
