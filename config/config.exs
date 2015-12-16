use Mix.Config

config :logger, :console,
  metadata: [:module, :line],
  format: {Adz, :text}

config :carrier, credentials_dir: "/tmp/carrier_#{Mix.env}/credentials"
