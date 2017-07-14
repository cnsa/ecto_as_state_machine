defmodule EctoStateMachine do
  defmacro __using__(opts) do
    app     = Mix.Project.config[:app]
    default_repo = Application.get_env(app, :ecto_repos, []) |> List.first
    repo    = Keyword.get(opts, :repo, default_repo)
    states  = Keyword.get(opts, :states)
    initial = Keyword.get(opts, :initial)
    events  = Keyword.get(opts, :events)
      |> Enum.map(fn(event) ->
        Keyword.put_new(event, :callback, quote do: fn(model) -> model end)
      end)
      |> Enum.map(fn(event) ->
        Keyword.update!(event, :callback, &Macro.escape/1)
      end)

    quote bind_quoted: [states: states, events: events, repo: repo, initial: initial ] do
      alias Ecto.Changeset

      events
      |> Enum.each(fn(event) ->
        unless event[:to] in states do
          raise "Target state :#{event[:to]} is not present in @states"
        end

        def unquote(event[:name])(model) do
          model
          |> Changeset.change(%{state: "#{unquote(event[:to])}"})
          |> unquote(event[:callback]).()
          |> _validate_state_transition(unquote(event), _valid_model(model))
        end

        def unquote(:"#{event[:name]}!")(model) do
          case unquote(event[:name])(model) |> unquote(repo).update do
            { :ok, new_model } -> new_model
            e -> e
          end
        end

        def unquote(:"can_#{event[:name]}?")(model) do
          :"#{state_with_initial(model.state)}" in unquote(event[:from])
        end
      end)

      states
      |> Enum.each(fn(state) ->
        def unquote(:"#{state}?")(model) do
          :"#{state_with_initial(model.state)}" == unquote(state)
        end
      end)

      defp unquote(:_valid_model)(%Ecto.Changeset{} = cs) do
        case cs do
          %{ data:  model } -> model
          %{ model: model } -> model
        end
      end
      defp unquote(:_valid_model)(model), do: model

      defp unquote(:_validate_state_transition)(changeset, event, model) do
        state = state_with_initial(model.state)

        if :"#{state}" in event[:from] do
          changeset
        else
          changeset
          |> Changeset.add_error("state",
             "You can't move state from :#{state || "nil"} to :#{event[:to]}")
        end
      end

      def unquote(:state)(model) do
        "#{state_with_initial(model.state)}"
      end

      defp state_with_initial(state) do
        if :"#{state}" in unquote(states) do
          state
        else
          unquote(initial)
        end
      end
    end
  end
end
