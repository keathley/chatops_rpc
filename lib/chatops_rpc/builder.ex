defmodule ChatopsRPC.Builder do
  defmacro __using__(_) do
    quote do
      @before_compile unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :commands, accumulate: true)

      import unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(%{module: module}) do
    commands = Module.get_attribute(module, :commands)
    commands_ast = for rpc <- commands do
      compile_command(rpc)
    end

    command_list =
      commands
      |> Enum.map(fn rpc -> {rpc.path, Map.delete(rpc, :f)} end)
      |> Enum.into(%{})
      |> Macro.escape

    quote do
      def namespace, do: @namespace

      def commands do
        unquote(command_list)
      end

      unquote(commands_ast)
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

      @commands %{
        regex: Regex.source(regex),
        help: String.trim_trailing(help),
        path: Atom.to_string(name),
        params: Regex.names(regex),
        f: f,
      }
    end
  end

  defp compile_command(rpc) do
    quote do
      def dispatch_command(unquote(rpc.path), command) do
        unquote(rpc.f).(command)
      end
    end
  end
end
