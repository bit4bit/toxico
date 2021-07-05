defmodule Toxico.MixProject do
  use Mix.Project

  def project do
    [
      app: :toxico,
      version: "0.1.0",
      elixir: "~> 1.12",
      description: "tox protocol binding",
      compilers: [:unifex, :bundlex] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      elixir_options: [
        warnings_as_errors: true
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
      {:unifex, "~> 0.4.0"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/bit4bit/toxico"},
      files: ~w(lib c_src bundlex.exs mix.exs README.md LICENSE)
    ]
  end
end
