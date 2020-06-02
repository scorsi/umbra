defmodule Umbra.MixProject do
  use Mix.Project

  def project do
    [
      app: :umbra,
      name: "Umbra",
      version: "0.0.2",
      elixir: "~> 1.7",
      source_url: "https://github.com/scorsi/umbra",
      homepage_url: "https://github.com/scorsi/umbra",
      test_coverage: [
        tool: ExCoveralls
      ],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      description: description(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    "Umbra helps you make your GenServer rocks in lesser code"
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: [:dev, :test]},
      {:excoveralls, ">= 0.0.0", only: [:dev, :test]},
      {:inch_ex, ">= 0.0.0", only: [:dev, :docs, :test]},
      {:credo, ">= 0.0.0", only: [:dev, :test]},
    ]
  end

  defp package() do
    [
      name: "umbra",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*),
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/scorsi/umbra",
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
