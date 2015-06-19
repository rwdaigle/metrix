defmodule Metrix.Mixfile do
  use Mix.Project

  def project do
    [app: :metrix,
     version: "0.2.0",
     description: description,
     elixir: "~> 1.0",
     deps: deps,
     package: package,
     source_url: "https://github.com/rwdaigle/metrix"]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [applications: [:logger],
     mod: {Metrix, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:logfmt, "~> 3.0"},
      {:ex_doc, "~> 0.7", only: :dev}
    ]
  end

  defp description do
    """
    Metrix is a library to log custom application metrics, in a well-structured,
    human *and* machine readable format, for use by downstream log processing
    systems (like Librato, Reimann, etc...)
    """
  end

  defp package do
    [contributors: ["Ryan Daigle <ryan.daigle@gmail.com>"],
    licenses: ["MIT"],
    links: %{"GitHub" => "https://github.com/rwdaigle/metrix"},
    files: ~w(mix.exs lib README.md)]
  end
end
