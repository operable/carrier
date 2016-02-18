defmodule Carrier.Mixfile do
  use Mix.Project

  def project do
    [app: :carrier,
     version: "0.0.1",
     elixir: "~> 1.1",
     elixirc_paths: elixirc_paths(Mix.env),
     elixirc_options: [warnings_as_errors: System.get_env("ALLOW_WARNINGS") == nil],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger,
                    :emqttc]]
  end

  defp deps do
    [{:enacl, github: "jlouis/enacl", tag: "0.15.0"},
     {:emqttc, github: "emqtt/emqttc", branch: "master"},
     {:adz, git: "git@github.com:operable/adz", ref: "140db3cc4dbecee1a2b68e8d0b18d7c64f27996a"},
     {:uuid, "~> 1.1.3"},
     {:poison, "~> 1.5.2"}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]
end
