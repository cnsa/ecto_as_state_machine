defmodule EctoStateMachine.StateTest do
  use EctoStateMachine.EctoCase, async: true
  use ExSpec, async: true

  alias EctoStateMachine.{User, TestRepo}
  import EctoStateMachine.TestFactory

  @event [
    name:     :confirm,
    from:     [:unconfirmed],
    to:       :confirmed,
    callback: nil
  ]

  @states [:unconfirmed, :confirmed, :blocked, :admin]

  @initial nil

  setup_all do
    {
      :ok,
      unconfirmed_user: insert(:user, %{ state: "unconfirmed" }),
      confirmed_user:   insert(:user, %{ state: "confirmed" }),
      blocked_user:     insert(:user, %{ state: "blocked" }),
      admin:            insert(:user, %{ state: "admin" }),
      initial_user:     insert(:user, %{ state: ""}),
      not_found_state:  insert(:user, %{ state: "some"})
    }
  end

  describe ".update" do
    it "with success", context do
      value = EctoStateMachine.State.update(%{event: @event, states: @states, model: context[:unconfirmed_user], initial: @initial})
      assert match? %{changes: %{state: "confirmed"}}, value
    end

    it "with failure", context do
      value = EctoStateMachine.State.update(%{event: [
          name:     :confirm,
          from:     [:confirmed],
          to:       :confirmed,
          callback: nil
        ], states: @states,
        model: context[:blocked_user],
        initial: @initial})
      assert match?(%{valid?: false}, value)
    end
  end

  describe ".update!" do
    it "with success", context do
      EctoStateMachine.State.update!(%{repo: TestRepo, event: @event, states: @states, model: context[:unconfirmed_user], initial: @initial})
      user = TestRepo.get(User, context[:unconfirmed_user].id)
      assert match? %{state: "confirmed"}, user
    end

    it "with failure", context do
      value = EctoStateMachine.State.update!(%{repo: TestRepo, event: [
        name:     :confirm,
        from:     [:confirmed],
        to:       :confirmed,
        callback: nil
      ], states: @states, model: context[:blocked_user], initial: @initial})
      assert match?({:error, _}, value)
      user = TestRepo.get(User, context[:blocked_user].id)
      assert match? %{state: "blocked"}, user
    end
  end

  describe ".can_event?" do
    it "when true", context do
      assert EctoStateMachine.State.can_event?(%{repo: TestRepo,
        event: @event, states: @states,
        model: context[:unconfirmed_user],
        initial: @initial})
    end

    it "when false", context do
      refute EctoStateMachine.State.can_event?(%{repo: TestRepo,
        event: @event, states: @states,
        model: context[:blocked_user],
        initial: @initial})
    end
  end

  describe ".is_state?" do
    it "when true", context do
      assert EctoStateMachine.State.is_state?(%{
        states: @states,
        model: context[:confirmed_user],
        initial: @initial,
        state: :confirmed})
    end

    it "when false", context do
      refute EctoStateMachine.State.is_state?(%{
        states: @states,
        model: context[:unconfirmed_user],
        initial: @initial,
        state: :confirmed})
    end
  end

  describe ".state_with_initial" do
    it "with initial", context do
      value = EctoStateMachine.State.state_with_initial(nil, %{event: @event, states: @states, model: context[:unconfirmed_user], initial: "confirmed"})
      assert match? "confirmed", value
    end

    it "with state", context do
      value = EctoStateMachine.State.state_with_initial("confirmed", %{event: @event, states: @states, model: context[:unconfirmed_user], initial: @initial})
      assert match? "confirmed", value
    end

    it "without initial", context do
      value = EctoStateMachine.State.state_with_initial(nil, %{event: @event, states: @states, model: context[:unconfirmed_user], initial: @initial})
      assert match? nil, value
    end
  end
end
