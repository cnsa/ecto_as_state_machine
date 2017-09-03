defmodule EctoAsStateMachine.EctoCase do
  use ExUnit.CaseTemplate

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(EctoAsStateMachine.TestRepo)
  end
end
