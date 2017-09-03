defmodule EctoStateMachine.State do
  alias Ecto.Changeset

  def update(%{event: event, model: model, states: states, initial: initial, column: column}) do
    model
    |> Changeset.change(%{state: "#{event[:to]}"})
    |> run_callback(event[:callback])
    |> validate_state_transition(%{
      event: event,
      column: column,
      model: valid_model(model),
      states: states,
      initial: initial
    })
  end
  def update(%{} = config) do
    update(Map.put_new(config, :column, :state))
  end

  def update!(%{repo: repo} = config) do
    case update(config) |> repo.update do
      { :ok, new_model } -> new_model
      e -> e
    end
  end

  def can_event?(%{model: model, event: event, column: column} = config) do
    :"#{state_with_initial(Map.get(model, column), config)}" in event[:from]
  end
  def can_event?(%{} = config) do
    can_event?(Map.put_new(config, :column, :state))
  end

  def is_state?(%{model: model, state: state, column: column} = config) do
    :"#{state_with_initial(Map.get(model, column), config)}" == state
  end
  def is_state?(%{} = config) do
    is_state?(Map.put_new(config, :column, :state))
  end

  def state_with_initial(state, %{initial: initial, states: states}) do
    if :"#{state}" in states do
      state
    else
      initial
    end
  end

  defp validate_state_transition(changeset, %{event: event, model: model, column: column} = config) do
    state = state_with_initial(Map.get(model, column), config)

    if :"#{state}" in event[:from] do
      changeset
    else
      changeset
      |> Changeset.add_error("state",
           "You can't move state from :#{state || "nil"} to :#{event[:to]}")
    end
  end
  defp validate_state_transition(changeset, %{} = config) do
    validate_state_transition(changeset, Map.put_new(config, :column, :state))
  end

  defp run_callback(model, callback) when is_function(callback, 1), do: callback.(model)
  defp run_callback(model, _), do: model

  defp valid_model(%{ data:  model }), do: model
  defp valid_model(%{ model:  model }), do: model
  defp valid_model(model), do: model
end
