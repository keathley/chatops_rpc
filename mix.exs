defmodule ChatopsRPC.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :chatops_rpc,
      version: @version,
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "ChatopsRPC",
      source_url: "https://github.com/keathley/chatops_rpc",
      docs: docs(),
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "test/support"]
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
      {:norm, "~> 0.10"},
      {:plug, "~> 1.8"},
      {:jason,  "~> 1.2"},
      {:finch, "~> 0.3"},
      {:fawkes, "~> 0.4"},

      {:plug_cowboy, "~> 2.1", only: [:dev, :test]},
      {:ex_doc, "~> 0.19", only: [:dev, :test]},
      {:x509, "~> 0.8", only: [:dev, :test]},
    ]
  end

  def description do
    """
    An elixir implementation of ChatopsRPC
    """
  end

  def package do
    [
      name: "chatops_rpc",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/keathley/chatops_rpc"}
    ]
  end

  def docs do
    [
      source_ref: "v#{@version}",
      source_url: "https://github.com/keathley/chatops_rpc",
      main: "ChatopsRPC",
    ]
  end
end
