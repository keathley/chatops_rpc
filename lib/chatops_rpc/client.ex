defmodule ChatopsRPC.Client do
  @moduledoc """
  """
  use Supervisor

  alias ChatopsRPC.Client.{
    Commands,
    Endpoints,
  }

  def start_link(opts) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, opts, name: opts[:name])
  end

  def start_polling(server \\ __MODULE__, url) do
    Endpoints.put(server, url)
  end

  def private_key(server) do
    :persistent_term.get({server, :private_key})
  end

  def init(opts) do
    key = case opts[:private_key] do
      nil -> raise ArgumentError, "chatops client requires a `:private_key`"
      contents -> decode_key(contents)
    end
    :persistent_term.put({opts[:name], :private_key}, key)

    children = [
      {Commands, name: commands_name(opts[:name])},
      {Endpoints, name: opts[:name], commands: commands_name(opts[:name])},
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  defp commands_name(name) do
    :"#{name}.Commands"
  end

  defp decode_key(contents) do
    [entry] = :public_key.pem_decode(contents)
    :public_key.pem_entry_decode(entry)
  end
end

