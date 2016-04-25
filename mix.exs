defmodule RePG2.Mixfile do
  use Mix.Project

  @version "0.0.3"

  def project do
    [
      app: :repg2,
      version: @version,
      elixir: "~> 1.2",
      elixirc_paths: elixirc_paths(Mix.env),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      dialyzer: [plt_file: ".dialyxir/.local.plt"],
      source_url: "https://github.com/antipax/repg2",
      docs: [
        main: "readme",
        extras: ["README.md"],
        source_ref: "v#{@version}"
      ],
      description: description,
      package: package,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
    ]
  end

  def application do
    [
      applications: [:logger],
      mod: {RePG2.Application, []}
    ]
  end

  defp deps do
    [
      {:credo, "~> 0.3", only: [:dev, :test]},
      {:dialyxir, "~> 0.3", only: [:dev, :test]},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev},
      {:excoveralls, "~> 0.4", only: :test},
      {:inch_ex, only: :docs}
    ]
  end

  defp description do
    "A highly-documented translation of the original Erlang pg2 implementation to Elixir for educational purposes."
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Eric Entin"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/antipax/repg2"
      }
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]
end
