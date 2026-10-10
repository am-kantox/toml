defmodule Toml.MixProject do
  use Mix.Project

  @version "0.7.0"
  @source_url "https://github.com/bitwalker/toml-elixir"

  def project do
    [
      app: :toml,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() not in [:dev, :test],
      description: "An implementation of TOML for Elixir projects",
      package: package(),
      deps: deps(),
      aliases: aliases(Mix.env()),
      dialyzer: dialyzer(),
      docs: docs(),
      elixirc_paths: elixirc_paths(Mix.env()),
      escript: escript(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def cli do
    [
      preferred_envs: [
        bench: :bench,
        "bench.decoder": :bench,
        "bench.lexer": :bench,
        docs: :docs,
        "hex.publish": :docs,
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:benchee, "~> 1.3", only: [:bench]},
      {:benchee_html, "~> 1.0", only: [:bench]}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Paul Schoenfelder"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      source_ref: @version,
      extras: [
        LICENSE: [title: "License"],
        "README.md": [title: "Overview"]
      ],
      formatters: ["html"]
    ]
  end

  def escript do
    [
      main_module: Toml.CLI,
      name: "toml",
      embed_elixir: true,
      app: nil
    ]
  end

  defp aliases(_env) do
    [
      quality: ["format", "credo --strict", "dialyzer"],
      "quality.ci": [
        "format --check-formatted",
        "credo --strict",
        "dialyzer"
      ],
      "compile-check": [
        "compile --warnings-as-errors",
        "format --check-formatted --dry-run",
        "dialyzer --format dialyxir"
      ],
      clean: ["clean", &clean/1],
      bench: ["bench.decoder", "bench.lexer"],
      "bench.decoder": ["run bench/bench.decoder.exs"],
      "bench.lexer": ["run bench/bench.lexer.exs"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:bench), do: ["lib", "bench/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp dialyzer do
    [
      plt_file: {:no_warn, ".dialyzer/dialyzer.plt"},
      plt_add_deps: :app_tree,
      plt_add_apps: [:mix],
      plt_core_path: ".dialyzer",
      list_unused_filters: true,
      ignore_warnings: ".dialyzer/ignore.exs"
    ]
  end

  defp clean(_args) do
    toml = Path.join([__DIR__, "bin", "toml"])

    if File.exists?(toml) do
      _ = File.rm(toml)
    end
  end
end
