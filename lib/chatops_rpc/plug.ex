defmodule ChatopsRPC.Plug do
  @moduledoc """
  Plug for adding chatops commands to your application.
  """
  @behaviour Plug

  import Plug.Conn

  alias ChatopsRPC.Server

  def init(opts) do
    handler = Keyword.fetch!(opts, :handler)
    Code.ensure_loaded(handler)

    server = Keyword.get(opts, :server) || ChatopsRPC.Server

    %{handler: handler, server: server}
  end

  def call(conn, %{handler: handler, server: server}) do
    with {:ok, conn} <- validate_url(conn, server),
         {:ok, conn} <- validate_timestamp(conn),
         {:ok, conn} <- validate_nonce(conn, server),
         {:ok, conn} <- validate_signature(conn),
         :ok         <- validate_authentication(conn, server) do
      handle_request(conn, handler)
    else
      {:error, error} ->
        conn
        |> put_resp_header("content-type", "application/json")
        |> send_resp(403, Jason.encode!(%{error: error}))
        |> halt()
    end
  end

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
    |> put_resp_header("content-type", "application/json")
    |> send_resp(200, body)
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
    |> put_resp_header("content-type", "application/json")
    |> send_resp(201, body)
  end

  def handle_request(conn, _handler) do
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(404, Jason.encode!(%{error: "Method not found"}))
    |> halt()
  end

  defp validate_url(conn, server) do
    url = ChatopsRPC.Server.base_url(server)

    if url == nil do
      raise ChatopsRPC.ConfigurationError, "You need to set the servers base_url to authenticate chatops rpcs"
    end

    full_url = url <> conn.request_path

    {:ok, put_private(conn, :chatops_url, full_url)}
  end

  defp validate_timestamp(conn) do
    case get_req_header(conn, "chatops-timestamp") do
      [timestamp] ->
        # Timestamp must be within 1 minute of our server time
        {:ok, ts, _}    = DateTime.from_iso8601(timestamp)
        now             = DateTime.utc_now()
        minute_ago      = DateTime.add(now, -60, :second)
        minute_from_now = DateTime.add(now, 60, :second)
        if DateTime.compare(ts, minute_ago) == :gt && DateTime.compare(ts, minute_from_now) == :lt do
          {:ok, put_private(conn, :chatops_ts, timestamp)}
        else
          {:error, "Chatops timestamp must be within 1 minute of server time"}
        end

      [] ->
        {:error, "Chatops timestamp was not provided"}
    end
  end

  defp validate_nonce(conn, server) do
    case get_req_header(conn, "chatops-nonce") do
      [nonce] ->
        case Server.store_nonce(server, nonce) do
          :ok ->
            {:ok, put_private(conn, :chatops_nonce, nonce)}

          :taken ->
            {:error, "Nonces cannot be re-used"}
        end

      [] ->
        {:error, "Chatops-Nonce header is required"}
    end
  end

  defp validate_signature(conn) do
    case get_req_header(conn, "chatops-signature") do
      [signature_string] ->
        case Regex.run(~r/Signature keyid=(.*),signature=(.*)$/, signature_string) do
          [^signature_string, _keyid, signature] ->
            {:ok, put_private(conn, :chatops_signature, signature)}

          _ ->
            {:error, "Invalid Chatops-Signature header"}
        end

      [] ->
        {:error, "Chatops-Signature is required"}
    end
  end

  defp validate_authentication(conn, server) do
    signature_string = """
    #{conn.private[:chatops_url]}
    #{conn.private[:chatops_nonce]}
    #{conn.private[:chatops_ts]}
    #{conn.private[:chatops_body]}
    """
    signature = Base.decode64!(conn.private[:chatops_signature])

    pub_key = Server.public_key(server)
    alt_key = Server.alt_public_key(server)

    verify = fn key ->
      :public_key.verify(signature_string, :sha256, signature, key)
    end

    if verify.(pub_key) || (alt_key && verify.(alt_key)) do
      :ok
    else
      {:error, "Request signature is not authenticated"}
    end
  end
end
