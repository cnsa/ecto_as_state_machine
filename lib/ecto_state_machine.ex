defmodule EctoAsStateMachine do
  defmodule Helpers do
    defmacro easm(opts) do
      app          = Mix.Project.config[:app]
      default_repo = Application.get_env(app, :ecto_repos, []) |> List.first

      repo    = Keyword.get(opts, :repo, default_repo)
      valid_states  = Keyword.get(opts, :states)
      column  = Keyword.get(opts, :column, :state)
      initial = Keyword.get(opts, :initial)
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
        function_prefix: function_prefix
      ] do
        alias Ecto.Changeset

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
            EctoAsStateMachine.State.update(%{
              event: unquote(event),
              model: model,
              column: unquote(column),
              states: unquote(valid_states),
              initial: unquote(initial)
            })
          end

          def unquote(:"#{event[:name]}!")(model) do
            EctoAsStateMachine.State.update!(%{
              repo: unquote(repo),
              event: unquote(event),
              model: model,
              column: unquote(column),
              states: unquote(valid_states),
              initial: unquote(initial)
            })
          end

          def unquote(:"can_#{event[:name]}?")(model) do
            EctoAsStateMachine.State.can_event?(%{
              event: unquote(event),
              model: model,
              column: unquote(column),
              states: unquote(valid_states),
              initial: unquote(initial)
            })
          end
        end)

        valid_states
        |> Enum.each(fn(state) ->
          def unquote(:"#{state}?")(model) do
            EctoAsStateMachine.State.is_state?(%{
              model: model,
              column: unquote(column),
              state: unquote(state),
              states: unquote(valid_states),
              initial: unquote(initial)
            })
          end
        end)

        def unquote(column)(model) do
          "#{EctoAsStateMachine.State.state_with_initial(Map.get(model, unquote(column)), %{states: unquote(valid_states), initial: unquote(initial)})}"
        end
      end
    end
  end

  @doc false
  defmacro __using__(_) do
    quote do
      import EctoAsStateMachine.Helpers
    end
  end
end
