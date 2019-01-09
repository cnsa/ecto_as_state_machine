defmodule EctoAsStateMachine.Mixfile do
  use Mix.Project

  @project_url "https://github.com/cnsa/ecto_as_state_machine"
  @version "2.0.0"

  def project do
    [
      app: :ecto_as_state_machine,
      version: @version,
      elixir: "~> 1.3",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      source_url: @project_url,
      homepage_url: @project_url,
      description:
        "State machine pattern for Ecto. I tried to make it similar as possible to ruby's gem 'aasm'",
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env:
        cli_env_for(:test, [
          "coveralls",
          "coveralls.detail",
          "coveralls.html",
          "coveralls.post"
        ])
    ]
  end

  defp elixirc_paths(:test), do: elixirc_paths() ++ ["test/support"]
  defp elixirc_paths(_), do: elixirc_paths()
  defp elixirc_paths(), do: ["lib"]

  def application do
    [
      applications: app_list(Mix.env())
    ]
  end

  def app_list(:test), do: app_list() ++ [:ecto, :postgrex, :ex_machina]
  def app_list(_), do: app_list()
  def app_list, do: [:logger]

  defp deps do
    [
      {:ecto, "~> 2.0 or ~> 3.0"},
      {:ecto_sql, "~> 3.0", only: :test},
      {:postgrex, ">= 0.0.0", only: :test},
      {:ex_machina, "~> 2.2.2", only: :test},
      {:ex_doc, "~> 0.11", only: :dev, runtime: false},
      {:earmark, ">= 0.0.0", only: :dev},
      {:ex_spec, "~> 2.0", only: :test},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.5", only: :test}
    ]
  end

  defp cli_env_for(env, tasks) do
    Enum.reduce(tasks, [], fn key, acc -> Keyword.put(acc, :"#{key}", env) end)
  end

  defp package do
    [
      name: :ecto_as_state_machine,
      files: [
        "lib/ecto_as_state_machine.ex",
        "lib/ecto_as_state_machine/state.ex",
        "mix.exs",
        "README.md",
        "LICENSE.txt"
      ],
      maintainers: ["Alexander Merkulov"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @project_url
      }
    ]
  end

  defp git_tag(_args) do
    System.cmd("git", ["tag", "v" <> Mix.Project.config()[:version]])
    System.cmd("git", ["push", "--tags"])
  end

  defp aliases do
    [
      test: ["ecto.drop --quiet", "ecto.create --quiet", "ecto.migrate", "test"],
      publish: ["hex.publish", "hex.publish docs", &git_tag/1],
      tag: [&git_tag/1]
    ]
  end
end
