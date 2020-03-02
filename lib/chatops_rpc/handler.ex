defmodule ChatopsRPC.Handler do
  @moduledoc """
  """
  use Fawkes.Listener

  alias Fawkes.Event.Message
  alias ChatopsRPC.Client

  require Logger

  def init(state) do
    state =
      state
      |> Keyword.put_new(:client, ChatopsRPC.Client)
      |> Map.new()

    {:ok, state}
  end

  respond(~r/rpc add (\S+)/, fn [url], event, state ->
    uri = URI.parse(url)

    if uri.scheme != "https" && state[:mode] != :test do
      reply(event, "ChatopsRPC is HTTPS only")
    else
      url = URI.to_string(uri)

      case Client.start_polling(state.client, url) do
        :ok ->
          reply(event, "Okay, I'll poll #{url} for chatops.")

        error ->
          Logger.error(fn -> "Error adding chatops: #{inspect error}" end)
          # Event.reply(event, "The prefix has already been taken")
          nil
      end
    end

    state
  end)

  respond(~r/rpc list/, fn _, event, state ->
    list =
      Client.list()
      |> Enum.map(fn {prefix, info} -> "#{prefix} - #{info.url}" end)
      |> Enum.join("\n")

    code(event, list)
  end)

  listen(
    fn event, state ->
      if match?(%Message{}, event) do
        true
      else
        false
      end
    end,
    fn _matches, event, state ->
      Enum.each(Client.methods(), fn method ->
        maybe_call_method(event, method, state)
      end)

      state
    end
  )

  defp maybe_call_method(%Message{}=event, method, state) do
    text = cond do
      String.starts_with?(event.text, event.bot_name) ->
        String.trim_leading(event.text, event.bot_name)

      event.bot_alias && String.starts_with?(event.text, event.bot_alias) ->
        String.trim_leading(event.text, event.bot_alias)

      true ->
        ""
    end

    case Regex.named_captures(method.regex, text) do
      nil ->
        nil

      matches ->
        data = %{
          user: event.user,
          room_id: event.channel.name,
          method: method.name,
          params: matches,
        }

        case Client.call(state.client, method.url, method.path, data) do
          {:ok, resp} ->
            say(event, resp)

          {:error, error} ->
            Logger.error(fn -> "Error calling rpc: #{inspect error}" end)
        end
    end
  end
  defp maybe_call_method(_, _, _), do: nil
end
