defmodule EctoStateMachine.TestFactory do
  use ExMachina.Ecto, repo: EctoStateMachine.TestRepo
  alias EctoStateMachine.{User, UserWithInitial}

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
