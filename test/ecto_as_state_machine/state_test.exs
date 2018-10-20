defmodule EctoAsStateMachine.StateTest do
  use EctoAsStateMachine.EctoCase, async: true
  use ExSpec, async: true

  alias EctoAsStateMachine.{User, TestRepo}
  import EctoAsStateMachine.TestFactory

  @event [
    name:     :confirm,
    from:     [:unconfirmed],
    to:       :confirmed,
    callback: nil
  ]

  @events [
    [
      name:     :confirm,
      from:     [:unconfirmed],
      to:       :confirmed
    ], [
      name:     :block,
      from:     [:confirmed],
      to:       :blocked
    ], [
      name:     :make_admin,
      from:     [:blocked],
      to:       :admin
    ]
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
    it "with new state", context do
      value = EctoAsStateMachine.State.update(%{event: @event, states: @states, model: context[:unconfirmed_user], initial: @initial})
      assert match? %{changes: %{state: "confirmed"}}, value
    end

    it "with same state", context do
      value = EctoAsStateMachine.State.update(%{event: [
          name:     :confirm,
          from:     [:confirmed],
          to:       :confirmed,
          callback: nil
        ], states: @states,
        model: context[:blocked_user],
        initial: @initial})
      assert match?(%{valid?: false}, value)
    end

    it "with new state and custom column name", context do
      other_states = [:unfirmed, :firmed]
      other_event = [
        name:     :firm,
        from:     [:unfirmed],
        to:       :firmed,
      ]
      value = EctoAsStateMachine.State.update(%{event: other_event, states: other_states, model: context[:unconfirmed_user], initial: "unfirmed", column: :some})
      assert match? %{changes: %{some: "firmed"}}, value
    end
  end

  describe ".next_state" do
    it "with success", context do
      value = EctoAsStateMachine.State.next_state(%{events: @events, states: @states, model: context[:unconfirmed_user], initial: @initial})
      assert match? %{changes: %{state: "confirmed"}}, value
    end

    it "with failure", context do
      value = EctoAsStateMachine.State.next_state(%{events: @events, states: @states,
        model: context[:admin],
        initial: @initial})
      assert match?(%{state: "admin"}, value)
    end
  end

  describe ".update!" do
    it "with success", context do
      EctoAsStateMachine.State.update!(%{repo: TestRepo, event: @event, states: @states, model: context[:unconfirmed_user], initial: @initial})
      user = TestRepo.get(User, context[:unconfirmed_user].id)
      assert match? %{state: "confirmed"}, user
    end

    it "with failure", context do
      value = EctoAsStateMachine.State.update!(%{repo: TestRepo, event: [
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
      assert EctoAsStateMachine.State.can_event?(%{repo: TestRepo,
        event: @event, states: @states,
        model: context[:unconfirmed_user],
        initial: @initial})
    end

    it "when false", context do
      refute EctoAsStateMachine.State.can_event?(%{repo: TestRepo,
        event: @event, states: @states,
        model: context[:blocked_user],
        initial: @initial})
    end
  end

  describe ".is_state?" do
    it "when true", context do
      assert EctoAsStateMachine.State.is_state?(%{
        states: @states,
        model: context[:confirmed_user],
        initial: @initial,
        state: :confirmed})
    end

    it "when false", context do
      refute EctoAsStateMachine.State.is_state?(%{
        states: @states,
        model: context[:unconfirmed_user],
        initial: @initial,
        state: :confirmed})
    end
  end

  describe ".state_with_initial" do
    it "with initial", context do
      value = EctoAsStateMachine.State.state_with_initial(nil, %{event: @event, states: @states, model: context[:unconfirmed_user], initial: "confirmed"})
      assert match? "confirmed", value
    end

    it "with state", context do
      value = EctoAsStateMachine.State.state_with_initial("confirmed", %{event: @event, states: @states, model: context[:unconfirmed_user], initial: @initial})
      assert match? "confirmed", value
    end

    it "without initial", context do
      value = EctoAsStateMachine.State.state_with_initial(nil, %{event: @event, states: @states, model: context[:unconfirmed_user], initial: @initial})
      assert match? nil, value
    end
  end
end
