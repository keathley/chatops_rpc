defmodule ChatopsRPC.TestPlug do
  use ChatopsRPC.Builder

  namespace :test_ops

  @help """
  <text> - Echo some text back to you
  """
  command :echo, ~r/echo (?<text>.*)?/, fn %{params: args} ->
    "#{args["text"]}"
  end
end

defmodule ChatopsRPC.TestRouter do
  use Plug.Router

  plug Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["text/*"],
    json_decoder: Jason,
    body_reader: {ChatopsRPC.Plug.BodyReader, :read_body, []}

  plug :match
  plug :dispatch

  forward "/_chatops", to: ChatopsRPC.Plug, handler: ChatopsRPC.TestPlug
end

defmodule ChatopsRPC.TestServer do
  def start do
    public_key = File.read!("test/support/chatops.key.pub")
    {:ok, _} = ChatopsRPC.Server.start_link(base_url: "http://localhost:4002", public_key: public_key)
    Plug.Cowboy.http ChatopsRPC.TestRouter, [], [port: 4002]
  end
end

