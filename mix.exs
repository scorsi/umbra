defmodule Umbra.MixProject do
  use Mix.Project

  @release_version "0.0.3"

  def project do
    [
      app: :umbra,
      name: "Umbra",
      version: @release_version,
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
      {:keyword_validator, "~> 1.0"},


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
      extras: ["README.md"],
      groups_for_extras: [],
      groups_for_modules: [
        Behaviours: [
          Umbra.Behaviour.Default,
          Umbra.Behaviour.Strict,
          Umbra.Behaviour.Tolerant,
        ],
        Extensions: [
          Umbra.Extension.NameSetter,
          Umbra.Extension.Registry,
          Umbra.Extension.Ping,
        ],
        Internal: [
          Umbra.Operations,
          Umbra.CodeGenerator,
          Umbra.DefinitionExtractor,
        ]
      ],
    ]
  end
end
