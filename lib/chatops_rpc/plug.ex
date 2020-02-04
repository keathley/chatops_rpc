defmodule ChatopsRPC.Plug do
  defmacro __using__(_) do
    quote do
      import ChatopsRPC.Plug
      Module.register_attribute(__MODULE__, :chatops_rpcs, accumulate: true)

      def init(opts) do
        opts
      end

      def call(conn, opts) do
        conn
      end
    end
  end

  defmacro namespace(name) do
    quote do
      @namespace unquote(name)
    end
  end

  defmacro chatop(name, match, help, f) do
    quote do
      @chatops_rpcs %{
        name: unquote(name),
        match: unquote(match),
        help: unquote(help),
        f: unquote(f),
      }
    end
  end
end
