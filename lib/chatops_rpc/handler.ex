defmodule ChatopsRPC.Handler do
  @behaviour Fawkes.EventHandler

  alias Fawkes.Event
  alias Fawkes.Event.Message

  def init(_) do
    {:ok, nil}
  end

  def handle_event(%Message{text: ".rpc add " <> text}=event, state) do
    uri = URI.parse(text)
    IO.inspect(uri, label: "URI")

    if uri.scheme != "https" do
      Event.reply(event, "ChatopsRPC is HTTPS only")
    end

    state
  end

  def handle_event(_, state) do
    state
  end
end
