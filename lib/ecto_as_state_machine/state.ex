
defmodule EctoAsStateMachine.State do

  @moduledoc """
  State callbacks
  """

  alias Ecto.Changeset

  @spec update(%{event: List.t(), model: Map.t(), states: List.t(), initial: String.t(), column: atom}) :: term | %{valid: false}
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

  @spec update!(%{repo: Ecto.Repo, event: List.t(), model: Map.t(), states: List.t(),
    initial: String.t(), column: atom}) :: term | {:error, term}
  def update!(%{repo: repo} = config) do
    value = update(config)
    case value |> repo.update do
      {:ok, new_model} -> new_model
      e -> e
    end
  end

  @spec next_state(%{events: List.t(), model: Map.t(), states: List.t(), initial: String.t(), column: atom}) :: term | %{valid: false}
  def next_state(%{events: events, model: model} = config) do
    event =
      events
      |> Enum.find(fn(e) -> can_event?(Map.put_new(config, :event, e)) end)

    if event do
      update(Map.put_new(config, :event, event))
    else
      model
    end
  end

  @spec can_event?(%{event: List.t(), model: Map.t(), column: atom}) :: true | false
  def can_event?(%{model: model, event: event, column: column} = config) do
    :"#{state_with_initial(Map.get(model, column), config)}" in event[:from]
  end
  def can_event?(%{} = config) do
    can_event?(Map.put_new(config, :column, :state))
  end

  @spec is_state?(%{event: List.t(), state: String.t(), column: atom}) :: true | false
  def is_state?(%{model: model, state: state, column: column} = config) do
    :"#{state_with_initial(Map.get(model, column), config)}" == state
  end
  def is_state?(%{} = config) do
    is_state?(Map.put_new(config, :column, :state))
  end

  @spec state_with_initial(String.t(), %{states: List.t(), initial: String.t()}) :: String.t() | String.t()
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

  defp valid_model(%{data: model}), do: model
  defp valid_model(%{model: model}), do: model
  defp valid_model(model), do: model
end
