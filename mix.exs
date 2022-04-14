defmodule UeberauthToken.MixProject do
  use Mix.Project
  @version "0.1.1"
  @elixir_versions ">= 1.6.0"

  def project do
    [
      app: :ueberauth_token,
      version: @version,
      elixir: @elixir_versions,
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      aliases: aliases(),
      preferred_cli_env: coveralls(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      mod: {UeberauthToken.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Stephen Moloney"],
      links: %{repository: "https://github.com/quiqupltd/ueberauth_token"},
      files: ~w(lib mix.exs README* CHANGELOG*)
    }
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ueberauth, "~> 0.7.0"},
      {:confex, "~> 3.3"},
      {:cachex, "~> 3.0"},

      # dev/test
      {:excoveralls, "~> 0.8.0", only: [:test], runtime: false},
      {:jason, "~> 1.0", only: [:test]},
      {:mapail, "~> 1.0", only: [:test]},
      {:mox, "~> 0.3.2", only: [:test]},
      {:credo, "~> 0.9", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.18", only: [:dev, :test]}
    ]
  end

  defp description do
    "UeberauthToken provides an oauth2 token authentication strategy
    leveraging functionality provided by ueberauth"
  end

  defp aliases do
    [
      prepare: ["deps.get", "clean", "format", "compile", "credo --strict"],
      test: ["test --no-start"]
    ]
  end

  defp coveralls do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]
  end
end
