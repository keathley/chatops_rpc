defmodule ChatopsRPC.TestPlug do
  use ChatopsRPC.Plug

  namespace :test_ops

  @help """
  <text> - Echo some text back to you
  """
  command :echo, ~r/(?<text>.*)?/, fn %{params: args} ->
    "#{args["text"]}"
  end
end

defmodule ChatopsRPC.TestRouter do
  use Plug.Router

  plug Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["text/*"],
    json_decoder: Jason

  plug :match
  plug :dispatch

  forward "/_chatops", to: ChatopsRPC.TestPlug
end

defmodule ChatopsRPC.TestServer do
  def start do
    Plug.Cowboy.http ChatopsRPC.TestRouter, [], [port: 4002]
  end
end

