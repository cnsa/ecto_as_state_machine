defmodule EctoStateMachine.UserWithInitial do
  use Ecto.Schema

  use EctoStateMachine,
    states: [:unconfirmed, :confirmed, :blocked, :admin],
    initial: :admin,
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
  end
end
