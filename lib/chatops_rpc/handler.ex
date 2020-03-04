defmodule ChatopsRPC.Handler do
  @moduledoc """
  A Fawkes handler that listens for rpc commands.
  """
  use Fawkes.Listener

  alias Fawkes.Event.Message
  alias Fawkes.Bot
  alias ChatopsRPC.Client

  require Logger

  @key "chatopsrpc.list"
  @argument_matcher "(?: --(?:.+))"

  def init(bot, state) do
    state =
      state
      |> Keyword.put_new(:client, ChatopsRPC.Client)
      |> Map.new()

    list = Bot.get(bot, @key) || %{}

    for {prefix, url} <- list do
      Client.add(state.client, url, prefix)
    end

    {:ok, state}
  end

  respond(~r/rpc debug (\S+)/, fn [url], event, state ->
    with {:ok, info} <- Client.API.listing(state.client, url),
         {:ok, encoded} <- Jason.encode(info) do
      reply(event, "Info for #{url}")
      code(event, encoded)
    else
      error ->
        reply(event, "Error calling #{url}")
        code(event, "#{inspect error}")
    end

    state
  end)

  respond(~r/rpc remove (\S+)/, fn [url], event, state ->
    Client.remove(state.client, url)
    store_new_prefixes(event.bot, state)
    reply(event, "Ok, I won't poll or run commands from #{url}")


    state
  end)

  respond(~r/rpc add (\S+) (#{@argument_matcher})*?/, fn [url], event, state ->
    uri      = URI.parse(url)
    args     = extract_arguments(event.text)
    prefix   = args["prefix"]
    endpoint = Client.list()[prefix]

    cond do
      uri.scheme != "https" && state[:mode] != :test ->
        reply(event, "Sorry, ChatopsRPC is HTTPS only")

      endpoint ->
        reply(event, "Sorry, #{prefix} is already associated with #{endpoint.url}")

      true ->
        url = URI.to_string(uri)

        case Client.add(state.client, url, prefix) do
          :ok ->
            store_new_prefixes(event.bot, state)
            reply(event, "Okay, I'll poll #{url} for chatops.")

          {:error, msg} ->
            reply(event, "Sorry, #{msg}")
            nil
        end
    end

    state
  end)

  respond(~r/rpc list/, fn _, event, state ->
    list =
      Client.list(state.client)
      |> Enum.map(fn {prefix, info} -> "#{prefix} - #{info.url}" end)
      |> Enum.join("\n")

    code(event, list)

    state
  end)

  listen(
    fn event, _state ->
      if match?(%Message{}, event) do
        cond do
          String.starts_with?(event.text, event.bot.bot_name) ->
            String.trim_leading(event.text, event.bot.bot_name)

          event.bot.bot_alias && String.starts_with?(event.text, event.bot.bot_alias) ->
            String.trim_leading(event.text, event.bot.bot_alias)

          true ->
            false
        end
      else
        false
      end
    end,
    fn text, event, state ->
      prefix = Enum.at(String.split(text, " "), 0)
      list = Client.list(state.client)
      endpoint = list[prefix]

      cond do
        # If we found an endpoint and the prefix is the entire string
        # then we return a help message
        endpoint && prefix == text ->
          help_message =
            endpoint.methods
            |> Enum.map(& &1[:help])
            |> Enum.join("\n")

          code(event, help_message)

        endpoint ->
          Enum.each(endpoint.methods, fn method ->
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

                case Client.call(state.client, endpoint.url, method.path, data) do
                  {:ok, resp} ->
                    say(event, resp)

                  {:error, error} ->
                    Logger.error(fn -> "Error calling rpc: #{inspect error}" end)
                end
            end
          end)

        true ->
          nil
      end

      state
    end
  )

  defp extract_arguments(text) do
    # In order to find arguments we split the string into tokens, and drop
    # everything until we find a string that starts with a `--`. This denotes
    # an argument. We then group all of the tokens until we hit the next word
    # that starts with an `--` or we run out of words.
    text
    |> String.split(" ")
    |> Enum.drop_while(fn w -> !String.starts_with?(w, "--") end)
    |> group_args([])
  end

  # This function words by keeping track of the current argument as the first
  # item in a list. If we get a new argument we cons the current onto the
  # args list and then cons the new arg onto that new list.
  # Once we've found everything we need to reverse all of the inner lists, join
  # the words into strings, and put the whole thing into a map.
  defp group_args([], args) do
    args
    |> Enum.map(fn {arg, words} -> {arg, Enum.reverse(words)} end)
    |> Enum.map(fn {arg, words} -> {String.trim_leading(arg, "--"), (if words == [], do: true, else: Enum.join(words, " "))} end)
    |> Enum.into(%{})
  end
  defp group_args([word | words], args) do
    if String.starts_with?(word, "--") do
      group_args(words, [{word, []} | args])
    else
      [{current, list} | args] = args
      group_args(words, [{current, [word | list]} | args])
    end
  end

  defp store_new_prefixes(bot, state) do
    prefixes =
      Client.list(state.client)
      |> Enum.map(fn {prefix, endpoint} -> {prefix, endpoint.url} end)
      |> Enum.into(%{})

    Bot.set(bot, "chatopsrpc.list", prefixes)
  end
end
