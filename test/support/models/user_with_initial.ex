defmodule EctoAsStateMachine.UserWithInitial do
  use Ecto.Schema

  use EctoAsStateMachine

  easm states: [:unconfirmed, :confirmed, :blocked, :admin],
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

  easm states: [:unfirmed, :firmed, :cked, :min],
    column: :some,
    initial: :min,
    events: [
      [
        name:     :firm,
        from:     [:unfirmed],
        to:       :firmed,
        callback: fn(model) -> Ecto.Changeset.change(model, confirmed_at: DateTime.utc_now |> DateTime.to_naive) end
      ], [
        name:     :ck,
        from:     [:firmed, :min],
        to:       :cked
      ], [
        name:     :make_min,
        from:     [:firmed],
        to:       :min
      ]
    ]

  schema "users" do
    field :state, :string
    field :some, :string
  end
end
