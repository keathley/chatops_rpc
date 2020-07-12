# ChatopsRpc

Docs: [https://hexdocs.pm/chatops_rpc](https://hexdocs.pm/chatops_rpc).

<!-- MDOC !-->

An elixir implementation of the [ChatopsRPC protocol](https://github.com/bhuga/hubot-chatops-rpc).
This repo provides both server side and client side implementations of the protocol
for use with Plug and Fawkes respectively.

## Servers

Define your chatops:

```elixir
defmodule MyApp.Chatops do
  use ChatopsRPC.Builder

  namespace :my_app

  @help """
  echo <text> - Echo some text back to you
  """
  command :echo, ~r/echo (?<text>.*)?/, fn %{params: args} ->
    "#{args["text"]}"
  end
end
```

Add the chatops plug to your router or phoenix endpoint:

```elixir
defmodule ChatopsRPC.TestRouter do
  use Plug.Router

  forward "/_chatops", to: ChatopsRPC.Plug, handler: MyApp.Chatops
end
```

You'll also need to add the chatops body parser to your plug parsers:

```elixir
plug Plug.Parsers,
  parsers: [:urlencoded, :json],
  pass: ["text/*"],
  json_decoder: Jason,
  body_reader: {ChatopsRPC.Plug.BodyReader, :read_body, []}
```

This step is required because chatops rpc needs the full body in order to
the client signature.

Finally, you'll need to add the server to your application's supervision tree:

```elixir
defmodule MyApp.Application do
  def start(_, _) do
    public_key = System.get_env("CHATOPS_PUBLIC_KEY")

    children = [
      {ChatopsRPC.Server, [base_url: "YOUR APPS URL", public_key: public_key]},
    ]
  end
end
```

The server is used to verify client signatures, store nonces, and other stateful tasks.

## Clients

Add the chatops handler to your fawkes bot:

```elixir
opts = [
  name: TestBot,
  bot_alias: ".",
  adapter: {Fawkes.Adapter.Slack, [token: config.slack_token]},
  brain: {Fawkes.Brain.Redis, []},
  handlers: [
    {ChatopsRPC.Handler, []},
  ]
]
Fawkes.start_link(opts)
```

Add the client module to your bots supervision tree:

```elixir
defmodule MyBot.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = [
      name: TestBot,
      bot_alias: ".",
      adapter: {Fawkes.Adapter.Slack, [token: config.slack_token]},
      brain: {Fawkes.Brain.Redis, []},
      handlers: [
        {ChatopsRPC.Handler, []},
      ]
    ]

    children = [
      {ChatopsRPC.Client, private_key: File.read!("private_key")},
      {Fawkes, opts},
    ]

    opts = [strategy: :one_for_one, name: TestBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Your bot should now be able to interact with rpc commands and send rpcs to servers.

<!-- MDOC !-->

## Should I use this?

This implementation is missing some features from the canonical implementation as
well as some tests around key pieces of functionality. But the rudimentary
functionality seems to be working correctly and should be safe to use in production.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `chatops_rpc` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:chatops_rpc, "~> 0.2.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/chatops_rpc](https://hexdocs.pm/chatops_rpc).

