Mix.Task.run "ecto.drop", ["quiet"]
Mix.Task.run "ecto.create", ["quiet"]
Mix.Task.run "ecto.migrate", []

{:ok, _} = EctoStateMachine.TestRepo.start_link
ExUnit.start()
