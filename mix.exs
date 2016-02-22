defmodule Carrier.Mixfile do
  use Mix.Project

  def project do
    [app: :carrier,
     version: "0.2",
     elixir: "~> 1.2",
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
     {:emqttc, github: "operable/emqttc", ref: "dc36f593822f8e01771a7edc780441fdfb2f7b15"},
     {:adz, git: "git@github.com:operable/adz", ref: "5a6431ec19349dd11b1b667616a64dec652e75b7"},
     {:uuid, "~> 1.1.3"},
     {:poison, "~> 1.5.2"}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]
end
