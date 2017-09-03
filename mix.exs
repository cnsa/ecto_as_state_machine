defmodule EctoAsStateMachine.Mixfile do
  use Mix.Project

  @project_url "https://github.com/cnsa/ecto_as_state_machine"
  @version "0.0.4"

  def project do
    [
      app: :ecto_as_state_machine,
      version: @version,
      elixir: "~> 1.3",
      elixirc_paths: elixirc_paths(Mix.env),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps(),
      source_url: @project_url,
      homepage_url: @project_url,
      description: "State machine pattern for Ecto. I tried to make it similar as possible to ruby's gem 'aasm'",
      package: package()
   ]
  end

  defp elixirc_paths(:test), do: elixirc_paths() ++ ["test/support"]
  defp elixirc_paths(_),     do: elixirc_paths()
  defp elixirc_paths(),        do: ["lib"]

  def application do
    [
      applications: app_list(Mix.env),
    ]
  end

  def app_list(:test), do: app_list() ++ [:ecto, :postgrex, :ex_machina]
  def app_list(_),     do: app_list()
  def app_list,        do: [:logger]

  defp deps do
    [
     {:ecto, "~> 2.0"},

     {:postgrex,   ">= 0.0.0", only: :test},
     {:ex_machina, "~> 2.0", only: :test},
     {:ex_spec,    "~> 2.0", only: :test}
    ]
  end

  defp package do
    [
      name: :ecto_as_state_machine,
      files: ["lib/ecto_as_state_machine.ex", "lib/ecto_as_state_machine/state.ex", "mix.exs"],
      maintainers: ["Alexander Merkulov"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @project_url
      }
    ]
  end

  defp aliases do
    ["test": ["ecto.drop --quiet", "ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
