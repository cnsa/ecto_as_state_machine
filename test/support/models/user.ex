defmodule EctoAsStateMachine.User do
  use Ecto.Schema
  import Ecto.Changeset, only: [cast: 3, validate_required: 2]

  @required_params []
  @optional_params [:state, :some, :confirmed_at]

  use EctoAsStateMachine

  easm(
    states: [:unconfirmed, :confirmed, :blocked, :admin],
    events: [
      [
        name: :confirm,
        from: [:unconfirmed],
        to: :confirmed,
        callback: fn model ->
          Ecto.Changeset.change(model,
            confirmed_at: %{(DateTime.utc_now() |> DateTime.to_naive()) | microsecond: {0, 0}}
          )
        end
      ],
      [
        name: :block,
        from: [:confirmed, :admin],
        to: :blocked
      ],
      [
        name: :make_admin,
        from: [:confirmed],
        to: :admin
      ]
    ]
  )

  easm(
    states: [:unfirmed, :firmed, :cked, :min],
    column: :some,
    events: [
      [
        name: :firm,
        from: [:unfirmed],
        to: :firmed,
        callback: fn model ->
          Ecto.Changeset.change(model,
            confirmed_at: %{(DateTime.utc_now() |> DateTime.to_naive()) | microsecond: {0, 0}}
          )
        end
      ],
      [
        name: :ck,
        from: [:firmed, :min],
        to: :cked
      ],
      [
        name: :make_min,
        from: [:firmed],
        to: :min
      ]
    ]
  )

  schema "users" do
    field(:state, :string)
    field(:some, :string)
    field(:confirmed_at, :naive_datetime)
  end

  def changeset(user, params \\ :empty) do
    user
    |> cast(params, @required_params ++ @optional_params)
    |> validate_required(@required_params)
  end
end
