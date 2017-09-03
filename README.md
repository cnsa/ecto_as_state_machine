# EctoStateMachine

[![Build Status](https://travis-ci.org/cnsa/your_state_machine.svg?branch=add-ci)](https://travis-ci.org/cnsa/your_state_machine)
![badge](https://img.shields.io/hexpm/v/ecto_state_machine.svg)

This package allows to use [finite state machine pattern](https://en.wikipedia.org/wiki/Finite-state_machine) in Ecto. Specify:

* states
* events
* transitions

and go:

``` elixir
defmodule User do
  use Web, :model

  use EctoStateMachine,
    states: [:unconfirmed, :confirmed, :blocked, :admin],
    initial: :unconfirmed,
    events: [
      [
        name:     :confirm,
        from:     [:unconfirmed],
        to:       :confirmed,
        callback: fn(model) -> Ecto.Changeset.change(model, confirmed_at: DateTime.utc_now |> DateTime.to_naive) end # yeah you can bring your own code to these functions.
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

now you can run:

``` elixir
user = Repo.get_by(User, id: 1)

new_user_changeset = User.confirm(user)  # => Safe transition user state to "confirmed". We can make him admin!
Repo.update(new_user_changeset) # => Update manually

new_user = User.confirm!(user)  # => Or auto-transition user state to "confirmed". We can make him admin!

User.confirmed?(new_user) # => true
User.admin?(new_user) # => false
User.can_confirm?(new_user)    # => false
User.can_make_admin?(new_user) # => true

new_user = User.make_admin!(new_user)

User.admin?(new_user) # => true
```

You can check out whole `test/dummy` directory to inspect how to organize sample app.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add ecto_state_machine to your list of dependencies in `mix.exs`:

        def deps do
          [{:ecto_state_machine, "~> 0.0.4"}]
        end

  2. Ensure ecto_state_machine is started before your application:

        def application do
          [applications: [:ecto_state_machine]]
        end

## Contributions

1. Clone repo: `git clone https://github.com/asiniy/ecto_state_machine.git`
1. Open directory `cd ecto_state_machine`
1. Install dependencies `mix deps.get`
1. Add feature
1. Test it: `mix test`

Once you've made your additions and mix test passes, go ahead and open a PR!

## Roadmap to 1.0

- [x] Cover by tests
- [ ] Custom db column name
- [x] Validation method for changeset indicates its value in the correct range
- [x] Initial value
- [x] CI
- [x] Add status? methods
- [x] Introduce it at elixir-radar and my blog
