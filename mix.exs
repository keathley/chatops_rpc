defmodule ChatopsRpc.MixProject do
  use Mix.Project

  def project do
    [
      app: :chatops_rpc,
      version: "0.1.0",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:redix, "~> 0.10"},
      {:norm, "~> 0.10"},
      {:plug, "~> 1.8"},
      {:mojito, "~> 0.6"},
      {:jason,  "~> 1.1"},
      {:fawkes, path: "../fawkes"},

      {:plug_cowboy, "~> 2.1", only: [:dev, :test]},
    ]
  end
end
