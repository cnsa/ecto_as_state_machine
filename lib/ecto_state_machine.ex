defmodule EctoStateMachine do
  defmacro __using__(opts) do
    app          = Mix.Project.config[:app]
    default_repo = Application.get_env(app, :ecto_repos, []) |> List.first

    repo    = Keyword.get(opts, :repo, default_repo)
    states  = Keyword.get(opts, :states)
    initial = Keyword.get(opts, :initial)
    events  = Keyword.get(opts, :events)
      |> Enum.map(fn(event) ->
        Keyword.put_new(event, :callback, quote(do: fn(model) -> model end))
      end)
      |> Enum.map(fn(event) ->
        Keyword.update!(event, :callback, &Macro.escape/1)
      end)

    quote bind_quoted: [
      states: states,
      events: events,
      repo: repo,
      initial: initial
    ] do
      alias Ecto.Changeset

      events
      |> Enum.each(fn(event) ->
        unless event[:to] in states do
          raise "Target state :#{event[:to]} is not present in @states"
        end

        def unquote(event[:name])(model) do
          EctoStateMachine.State.update(%{
            event: unquote(event),
            model: model,
            states: unquote(states),
            initial: unquote(initial)
          })
        end

        def unquote(:"#{event[:name]}!")(model) do
          EctoStateMachine.State.update!(%{
            repo: unquote(repo),
            event: unquote(event),
            model: model,
            states: unquote(states),
            initial: unquote(initial)
          })
        end

        def unquote(:"can_#{event[:name]}?")(model) do
          EctoStateMachine.State.can_event?(%{
            event: unquote(event),
            model: model,
            states: unquote(states),
            initial: unquote(initial)
          })
        end
      end)

      states
      |> Enum.each(fn(state) ->
        def unquote(:"#{state}?")(model) do
          EctoStateMachine.State.is_state?(%{
            model: model,
            state: unquote(state),
            states: unquote(states),
            initial: unquote(initial)
          })
        end
      end)

      def unquote(:state)(model) do
        "#{EctoStateMachine.State.state_with_initial(model.state, %{states: unquote(states), initial: unquote(initial)})}"
      end
    end
  end
end
