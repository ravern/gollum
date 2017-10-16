defmodule Gollum.Mixfile do
  use Mix.Project

  def project do
    [
      app: :gollum,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env == :prod,
      deps: deps(),
      package: package(),
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which files to compile per environment
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [
      {:httpoison, "~> 0.13"},
      {:ex_doc, "~> 0.17.1", only: :dev, runtime: false},
    ]
  end

  defp package do
    [
      description: "Robots.txt parser with caching. Modelled after Kryten.",
      maintainers: ["Ravern Koh"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ravernkoh/gollum"},
    ]
  end
end
