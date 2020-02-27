defmodule ChatopsRPC.Handler do
  @behaviour Fawkes.EventHandler

  alias Fawkes.Event
  alias Fawkes.Event.Message
  alias ChatopsRPC.Client

  def init(state) do
    state =
      state
      |> Keyword.put_new(:client, ChatopsRPC.Client)
      |> Map.new()

    {:ok, state}
  end

  def handle_event(%Message{text: ".rpc add " <> text}=event, state) do
    uri = URI.parse(text)
    IO.inspect(uri, label: "URI")

    if uri.scheme != "https" && state[:mode] != :test do
      Event.reply(event, "ChatopsRPC is HTTPS only")
    else
      url = URI.to_string(uri)
      Client.start_polling(state.client, url)
      # case Client.start_polling(state.client, url) do
      #   {:ok, _} ->
          Event.reply(event, "Okay, I'll poll #{url} for chatops.")

        # {:error, _} ->
        #   Event.reply(event, "The prefix has already been taken")
      # end
    end

    state
  end

  def handle_event(%Message{text: text}=event, state) do
    state
  end
end
