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
     {:adz, git: "git@github.com:operable/adz", ref: "07ba970e0bec955f1f3ed1c4771511139924c7fd"},
     {:uuid, "~> 1.0.1"},
     {:poison, "~> 1.5.0"}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]
end
