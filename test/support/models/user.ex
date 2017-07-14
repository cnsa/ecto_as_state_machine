defmodule EctoStateMachine.User do
  use Ecto.Schema
  import Ecto.Changeset, only: [cast: 3, validate_required: 2, validate_required: 3]

  @required_params ~w()
  @optional_params ~w(state confirmed_at)

  use EctoStateMachine,
    states: [:unconfirmed, :confirmed, :blocked, :admin],
    events: [
      [
        name:     :confirm,
        from:     [:unconfirmed],
        to:       :confirmed,
        callback: fn(model) -> Ecto.Changeset.change(model, confirmed_at: DateTime.utc_now |> DateTime.to_naive) end
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
    field :confirmed_at, :naive_datetime
  end

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, @required_params ++ @optional_params)
    |> validate_required(@required_params)
  end
end
