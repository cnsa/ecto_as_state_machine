defmodule EctoAsStateMachine do
  @moduledoc """
  This package allows to use [finite state machine pattern](https://en.wikipedia.org/wiki/Finite-state_machine) in Ecto.

  1. Add ecto_as_state_machine to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:ecto_as_state_machine, "~> 1.0"}]
  end

  ```

  2. Ensure ecto_as_state_machine is started before your application:

  ```elixir
  def application do
    [applications: [:ecto_as_state_machine]]
  end

  ```
  """

  alias EctoAsStateMachine.State
  alias Ecto.Repo
  alias Mix.Project

  defmodule Helpers do
    @moduledoc """
    ``` elixir
    ## Example model:
    defmodule User do
      use Web, :model

      use EctoAsStateMachine

      easm column: :state,
           initial: :unconfirmed,
           states: [:unconfirmed, :confirmed, :blocked, :admin],
           events: [
            [
              name:     :confirm,
              from:     [:unconfirmed],
              to:       :confirmed,
              callback: fn(model) ->
                # yeah you can bring your own code to these function.
                Ecto.Changeset.change(model, confirmed_at: DateTime.utc_now |> DateTime.to_naive)
              end
            ], [
              name:     :block,
              from:     [:confirmed, :admin],
              to:       :blocked
            ], [
              name:     :make_admin,
              from:     [:confirmed],
              to:       :admin
            ]
          ]

      schema "users" do
        field :state, :string
      end
    end
    ```
    ## Examples
        user = Repo.get_by(User, id: 1)
        #=> %User{}

        new_user_changeset = User.confirm(user)
        #=> %{changes: %{state: "confirmed"}}

        Repo.update(new_user_changeset)
        #=> true

        new_user = User.confirm!(user)
        #=> Or auto-transition user state to "confirmed". We can make him admin!

        User.confirmed?(new_user)
        #=> true
        User.admin?(new_user)
        #=> false
        User.can_confirm?(new_user)
        #=> false
        User.can_make_admin?(new_user)
        #=> true

        new_user = User.make_admin!(new_user)

        User.admin?(new_user)
        #=> true
    """

    @spec easm([repo: Repo, initial: String.t(), inline: boolean(),
      column: atom, events: List.t(), states: List.t()]) :: term
    defmacro easm(opts) do
      app          = Project.config[:app]
      default_repo = Application.get_env(app, :ecto_repos, []) |> List.first

      repo    = Keyword.get(opts, :repo, default_repo)
      valid_states  = Keyword.get(opts, :states)
      column  = Keyword.get(opts, :column, :state)
      initial = Keyword.get(opts, :initial)
      inline = Keyword.get(opts, :inline, false)
      events  = Keyword.get(opts, :events)
        |> Enum.map(fn(event) ->
          Keyword.put_new(event, :callback, quote(do: fn(model) -> model end))
        end)
        |> Enum.map(fn(event) ->
          Keyword.update!(event, :callback, &Macro.escape/1)
        end)

      function_prefix = if column == :state, do: nil, else: "#{column}_"

      quote bind_quoted: [
        valid_states: valid_states,
        events: events,
        column: column,
        repo: repo,
        initial: initial,
        inline: inline,
        function_prefix: function_prefix
      ] do
        def unquote(:"#{function_prefix}states")() do
          unquote(valid_states)
        end

        def unquote(:"#{function_prefix}events")() do
          unquote(events) |> Enum.map(fn(x) -> x[:name] end)
        end

        events
        |> Enum.each(fn(event) ->
          unless event[:to] in valid_states do
            raise "Target state :#{event[:to]} is not present in states"
          end

          def unquote(event[:name])(model) do
            State.update(%{
              event: unquote(event),
              model: model,
              column: unquote(column),
              states: unquote(valid_states),
              initial: unquote(initial)
            })
          end

          def unquote(:"#{event[:name]}!")(model) do
            State.update!(%{
              repo: unquote(repo),
              event: unquote(event),
              model: model,
              column: unquote(column),
              states: unquote(valid_states),
              initial: unquote(initial)
            })
          end

          def unquote(:"can_#{event[:name]}?")(model) do
            State.can_event?(%{
              event: unquote(event),
              model: model,
              column: unquote(column),
              states: unquote(valid_states),
              initial: unquote(initial)
            })
          end
        end)

        if inline do
          def unquote(:"#{function_prefix}next_state")(model) do
            State.next_state(%{
              events: unquote(events),
              model: model,
              column: unquote(column),
              states: unquote(valid_states),
              initial: unquote(initial)
            })
          end
        end

        valid_states
        |> Enum.each(fn(state) ->
          def unquote(:"#{state}?")(model) do
            State.is_state?(%{
              model: model,
              column: unquote(column),
              state: unquote(state),
              states: unquote(valid_states),
              initial: unquote(initial)
            })
          end
        end)

        def unquote(column)(model) do
          "#{State.state_with_initial(
            Map.get(model, unquote(column)),
            %{states: unquote(valid_states), initial: unquote(initial)}
          )}"
        end
      end
    end
  end

  @doc false
  defmacro __using__(_) do
    quote do
      import Helpers
    end
  end
end
