defmodule ChatopsRPC.Plug do
  defmacro __using__(_) do
    quote do
      @behaviour Plug

      @before_compile unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :commands, accumulate: true)

      import ChatopsRPC.Plug
    end
  end

  defmacro __before_compile__(%{module: module}) do
    commands = Module.get_attribute(module, :commands)
    commands_ast = compile_commands(commands)

    quote location: :keep do
      unquote(commands_ast)

      def init(opts), do: opts

      # TODO - Ensure we're valid with all of our headers here
      def call(%{method: "GET", path_info: []}=conn, opts) do
        with :ok <- validate_url(conn),
             :ok <- validate_timestamp(conn),
             :ok <- validate_headers(conn),
             :ok <- validate_nonce(conn),
             :ok <- validate_signature(conn),
             {:ok, rpc} <- validate_rpc(conn)
        do
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

      def call(%{method: "POST", path_info: [path]}=conn, opts) do
        {name, rpc} =
          @commands
          |> Enum.find(fn {name, rpc} -> rpc.path == path end)

        command = %{
          method: conn.body_params["method"],
          params: conn.body_params["params"],
          user: conn.body_params["user"],
          room_id: conn.body_params["room_id"],
        }

        result = dispatch_command(name, command)

        body = Jason.encode!(%{result: result})

        conn
        |> Plug.Conn.send_resp(201, body)
      end

      def call(conn, opts) do
        conn
      end
    end
  end

  # TODO - Validate namespace and command names with this: `/[a-Z0-9]\-_]+/`
  defmacro namespace(name) do
    quote do
      @namespace unquote(name)
    end
  end

  defmacro command(name, regex, f) do
    f = Macro.escape(f)

    quote bind_quoted: [name: name, regex: regex, f: f] do
      help = Module.get_attribute(__MODULE__, :help)
      Module.delete_attribute(__MODULE__, :help)

      @commands {name, %{
        regex: Regex.source(regex),
        help: help,
        path: Atom.to_string(name),
        params: Regex.names(regex),
        f: f,
      }}
    end
  end

  defp compile_commands(commands) do
    ast = for {name, rpc} <- commands do
      compile_command(name, rpc)
    end

    quote do
      unquote(ast)
    end
  end

  defp compile_command(name, rpc) do
    quote do
      def dispatch_command(unquote(name), command) do
        unquote(rpc.f).(command)
      end
    end
  end
end
