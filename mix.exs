defmodule Pchat.MixProject do
  use Mix.Project

  def project do
    [
      app: :pchat,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Pchat.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 2.13"},
      {:plug_cowboy, "~> 2.7.3"},
      {:jason, "~> 1.4.4"}
    ]
  end
end
