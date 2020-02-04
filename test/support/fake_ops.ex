defmodule ChatopsRPC.TestPlug do
  use ChatopsRPC.Plug

  namespace :test_ops

  chatop :echo, ~r/(?<text>.*)?/, "<text> - Echo some text back to you", fn msg ->
    "Echoing stuff back to you: #{msg.matches[:text]}"
  end
end

defmodule ChatopsRPC.TestRouter do
  use Plug.Router

  forward "/_chatops", to: ChatopsRPC.TestPlug
end

defmodule ChatopsRPC.TestServer do
  def start do
    Plug.Cowboy.http ChatopsRPC.TestRouter, [], [port: 4002]
  end
end

