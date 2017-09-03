defmodule EctoAsStateMachine.TestFactory do
  use ExMachina.Ecto, repo: EctoAsStateMachine.TestRepo
  alias EctoAsStateMachine.{User, UserWithInitial}

  def user_factory do
    %User{
      state: "started",
      some: "started"
    }
  end

  def user_with_initial_factory do
    %UserWithInitial{
      state: "",
      some: ""
    }
  end
end
