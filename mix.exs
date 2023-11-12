defmodule Wind.MixProject do
  use Mix.Project

  @source_url "https://github.com/bfolkens/wind"

  def project do
    [
      app: :wind,
      version: "0.3.1",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      erlc_paths: erlc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description(),
      source_url: @source_url,
      docs: docs()
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
      {:mint, "~> 1.5.1"},
      {:mint_web_socket, "~> 1.0.3"},
      {:castore, "~> 1.0"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/fixtures"]
  defp elixirc_paths(_), do: ["lib"]

  defp erlc_paths(:test), do: ["src", "test/compare"]
  defp erlc_paths(_), do: ["src"]

  defp package do
    [
      name: "wind",
      files: ~w(lib .formatter.exs mix.exs README.md),
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => @source_url <> "/blob/main/CHANGELOG.md"
      }
    ]
  end

  defp description do
    "Wind.  A pleasant Elixir websocket client library based on Mint."
  end

  defp docs do
    [
      deps: [],
      language: "en",
      formatters: ["html"],
      main: Wind,
      extras: [
        "CHANGELOG.md"
      ],
      skip_undefined_reference_warnings_on: [
        "CHANGELOG.md"
      ]
    ]
  end
end
