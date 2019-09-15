defmodule ChatopsRPC.Supervisor do
  @moduledoc false
  use Supervisor
  import Norm

  alias ChatopsRPC.Endpoints

  def opts_spec do
    opts = one_of([
      {:name, spec(is_atom())},
      {:storage, spec(is_atom())},
    ])

    coll_of(opts)
  end

  def start_link(opts) do
    conformed = conform!(opts, opts_spec())

    Supervisor.start_link(__MODULE__, conformed)
  end

  def init(opts) do
    children = [
      {opts[:storage], opts},
      {Endpoints, opts}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
