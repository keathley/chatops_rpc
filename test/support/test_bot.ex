defmodule ChatopsRPC.TestBot do
  @moduledoc false
  use Supervisor

  def start_link(parent) do
    Supervisor.start_link(__MODULE__, parent)
  end

  def init(parent) do
    children = [
      {ChatopsRPC.Client, private_key: File.read!("test/support/chatops.key")},
      {Fawkes, [
        name: TestBot,
        bot_name: "hal",
        bot_alias: ".",
        adapter: {Fawkes.Adapter.TestAdapter, [parent: parent]},
        brain: {Fawkes.Brain.InMemory, []},
        handlers: [
          {ChatopsRPC.Handler, [mode: :test]},
        ]
      ]},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
