use Mix.Config

config :ecto_as_state_machine,
  ecto_repos: [EctoAsStateMachine.TestRepo]

# Configure your database
config :ecto_as_state_machine, EctoAsStateMachine.TestRepo,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  username: System.get_env("USER"),
  password: "",
  database: "ecto_as_state_machine_test",
  pool_size: 10,
  port: 5432,
  priv: "priv/test_repo"

config :logger, level: :warn
