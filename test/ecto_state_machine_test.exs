defmodule EctoStateMachineTest do
  use EctoStateMachine.EctoCase, async: true
  use ExSpec, async: true

  alias EctoStateMachine.{User, UserWithInitial}
  import EctoStateMachine.TestFactory

  setup_all do
    {
      :ok,
      unconfirmed_user: insert(:user, %{ state: "unconfirmed", some: "unfirmed" }),
      confirmed_user:   insert(:user, %{ state: "confirmed", some: "firmed" }),
      blocked_user:     insert(:user, %{ state: "blocked", some: "cked" }),
      admin:            insert(:user, %{ state: "admin", some: "min" }),
      initial_user:     insert(:user, %{ state: "", some: "" }),
      not_found_state:  insert(:user, %{ state: "some", some: "some" })
    }
  end

  describe "states" do
    it "with list" do
      assert User.states == [:unconfirmed, :confirmed, :blocked, :admin]
    end

    it "with some list" do
      assert User.some_states == [:unfirmed, :firmed, :cked, :min]
    end

    def cs_user_error(context, method, value, true = _tuple) do
       {:error, cs} = cs_user_error(context, method, value, false)
       cs
    end
    def cs_user_error(context, method, value, _) do
      apply(User, method, [context[value]])
    end

    def cs_user_initial_error(context, method, value, true = _tuple) do
       {:error, cs} = cs_user_initial_error(context, method, value, false)
       cs
    end
    def cs_user_initial_error(context, method,  value, _) do
      apply(UserWithInitial, method, [context[value]])
    end

    context "without initial" do
      it "#state", context do
        state(context)
        some(context)

        assert User.state(context[:initial_user])    == ""
        assert User.some(context[:initial_user])     == ""
        assert User.state(context[:not_found_state]) == ""
        assert User.some(context[:not_found_state])  == ""
      end

      it "#state?", context do
        state?(context)
        some?(context)

        assert User.admin?(context[:initial_user]) == false
        assert User.min?(context[:initial_user])   == false

        assert User.admin?(context[:not_found_state]) == false
        assert User.min?(context[:not_found_state])   == false
      end
    end

    context "with initial" do
      it "#state", context do
        state(context, UserWithInitial)
        some(context, UserWithInitial)

        assert UserWithInitial.state(context[:initial_user]) == "admin"
        assert UserWithInitial.some(context[:initial_user])  == "min"

        assert UserWithInitial.state(context[:not_found_state]) == "admin"
        assert UserWithInitial.some(context[:not_found_state])  == "min"
      end

      it "#state?", context do
        state?(context, UserWithInitial)
        some?(context, UserWithInitial)

        assert UserWithInitial.admin?(context[:initial_user]) == true
        assert UserWithInitial.min?(context[:initial_user])   == true

        assert UserWithInitial.admin?(context[:not_found_state]) == true
        assert UserWithInitial.min?(context[:not_found_state])   == true
      end
    end

    defp state(context, model \\ User) do
      assert model.state(context[:unconfirmed_user]) == "unconfirmed"
      assert model.state(context[:confirmed_user])   == "confirmed"
      assert model.state(context[:blocked_user])     == "blocked"
      assert model.state(context[:admin])            == "admin"
    end

    defp some(context, model \\ User) do
      assert model.some(context[:unconfirmed_user]) == "unfirmed"
      assert model.some(context[:confirmed_user])   == "firmed"
      assert model.some(context[:blocked_user])     == "cked"
      assert model.some(context[:admin])            == "min"
    end

    defp state?(context, model \\ User) do
      # Initial
      assert model.unconfirmed?(context[:initial_user]) == false
      assert model.confirmed?(context[:initial_user])   == false
      assert model.blocked?(context[:initial_user])     == false

      assert model.unconfirmed?(context[:not_found_state]) == false
      assert model.confirmed?(context[:not_found_state])   == false
      assert model.blocked?(context[:not_found_state])     == false

      # All
      assert model.unconfirmed?(context[:unconfirmed_user]) == true
      assert model.unconfirmed?(context[:confirmed_user])   == false
      assert model.unconfirmed?(context[:blocked_user])     == false
      assert model.unconfirmed?(context[:admin])            == false

      assert model.confirmed?(context[:unconfirmed_user]) == false
      assert model.confirmed?(context[:confirmed_user])   == true
      assert model.confirmed?(context[:blocked_user])     == false
      assert model.confirmed?(context[:admin])            == false

      assert model.blocked?(context[:unconfirmed_user]) == false
      assert model.blocked?(context[:confirmed_user])   == false
      assert model.blocked?(context[:blocked_user])     == true
      assert model.blocked?(context[:admin])            == false

      assert model.admin?(context[:unconfirmed_user]) == false
      assert model.admin?(context[:confirmed_user])   == false
      assert model.admin?(context[:blocked_user])     == false
      assert model.admin?(context[:admin])            == true
    end

    defp some?(context, model \\ User) do
      # Initial
      assert model.unfirmed?(context[:initial_user]) == false
      assert model.firmed?(context[:initial_user])   == false
      assert model.cked?(context[:initial_user])     == false

      assert model.unfirmed?(context[:not_found_state]) == false
      assert model.firmed?(context[:not_found_state])   == false
      assert model.cked?(context[:not_found_state])     == false

      # All
      assert model.unfirmed?(context[:unconfirmed_user]) == true
      assert model.unfirmed?(context[:confirmed_user])   == false
      assert model.unfirmed?(context[:blocked_user])     == false
      assert model.unfirmed?(context[:admin])            == false

      assert model.firmed?(context[:unconfirmed_user]) == false
      assert model.firmed?(context[:confirmed_user])   == true
      assert model.firmed?(context[:blocked_user])     == false
      assert model.firmed?(context[:admin])            == false

      assert model.cked?(context[:unconfirmed_user]) == false
      assert model.cked?(context[:confirmed_user])   == false
      assert model.cked?(context[:blocked_user])     == true
      assert model.cked?(context[:admin])            == false

      assert model.min?(context[:unconfirmed_user]) == false
      assert model.min?(context[:confirmed_user])   == false
      assert model.min?(context[:blocked_user])     == false
      assert model.min?(context[:admin])            == true
    end
  end

  describe "events" do
    it "with list" do
      assert User.events == [:confirm, :block, :make_admin]
    end

    it "with some list" do
      assert User.some_events == [:firm, :ck, :make_min]
    end

    context "#confirm" do
      it "#confirm!", context do
        model = User.confirm!(context[:unconfirmed_user])
        assert model.state == "confirmed"

        check_confirm_errors(context, :confirm!, true)
      end

      it "#confirm! with changeset", context do
        model = User.changeset(context[:unconfirmed_user], %{confirmed_at: DateTime.utc_now |> DateTime.to_naive})
        |> User.confirm!
        assert model.state == "confirmed"
      end

      it "#confirm", context do
        cs = User.confirm(context[:unconfirmed_user])
        assert cs.changes.state == "confirmed"

        check_confirm_errors(context, :confirm)
      end

      it "#confirm with changeset", context do
        cs = User.changeset(context[:unconfirmed_user], %{confirmed_at: DateTime.utc_now |> DateTime.to_naive})
        |> User.confirm
        assert cs.changes.state == "confirmed"
      end

      defp check_confirm_errors(context, method, is_raise \\ false) do
        refute cs_user_initial_error(context, method, :initial_user, is_raise).valid?
        refute cs_user_initial_error(context, method, :not_found_state, is_raise).valid?
        refute cs_user_error(context, method, :initial_user, is_raise).valid?
        refute cs_user_error(context, method, :confirmed_user, is_raise).valid?
        refute cs_user_error(context, method, :blocked_user, is_raise).valid?
        refute cs_user_error(context, method, :admin, is_raise).valid?
      end
    end

    context "#block" do
      it "#block!", context do
        model = User.block!(context[:confirmed_user])
        assert model.state == "blocked"

        model = User.block!(context[:admin])
        assert model.state == "blocked"

        check_block_errors(context, :block!, true)
      end

      it "#block! with initials", context do
        model = UserWithInitial.block!(context[:initial_user])
        assert model.state == "blocked"

        model = UserWithInitial.block!(context[:not_found_state])
        assert model.state == "blocked"
      end

      it "#block", context do
        cs = User.block(context[:confirmed_user])
        assert cs.changes.state == "blocked"

        cs = User.block(context[:admin])
        assert cs.changes.state == "blocked"

        check_block_errors(context, :block)
      end

      it "#block with initials", context do
        cs = UserWithInitial.block(context[:initial_user])
        assert cs.changes.state == "blocked"

        cs = UserWithInitial.block(context[:not_found_state])
        assert cs.changes.state == "blocked"
      end

      defp check_block_errors(context, method, is_raise \\ false) do
        refute cs_user_initial_error(context, method, :unconfirmed_user, is_raise).valid?
        refute cs_user_initial_error(context, method, :blocked_user, is_raise).valid?
        refute cs_user_error(context, method, :initial_user, is_raise).valid?
        refute cs_user_error(context, method, :unconfirmed_user, is_raise).valid?
        refute cs_user_error(context, method, :blocked_user, is_raise).valid?
      end
    end

    context "#make_admin" do
      it "#make_admin!", context do
        model = User.make_admin!(context[:confirmed_user])
        assert model.state == "admin"

        check_admin_errors(context, :make_admin!, true)
      end

      it "#make_admin! with changeset", context do
        date = DateTime.utc_now |> DateTime.to_naive
        model = User.changeset(context[:confirmed_user], %{confirmed_at: date})
        |> User.make_admin!
        assert model.state        == "admin"
        assert model.confirmed_at == date
      end

      it "#make_admin", context do
        cs = User.make_admin(context[:confirmed_user])
        assert cs.changes.state == "admin"

        check_admin_errors(context, :make_admin)
      end

      it "#make_admin with changeset", context do
        date = DateTime.utc_now |> DateTime.to_naive
        cs = User.changeset(context[:confirmed_user], %{confirmed_at: date})
        |> User.make_admin
        assert cs.changes.state        == "admin"
        assert cs.changes.confirmed_at == date
      end

      defp check_admin_errors(context, method, is_raise \\ false) do
        refute cs_user_initial_error(context, method, :initial_user, is_raise).valid?
        refute cs_user_initial_error(context, method, :not_found_state, is_raise).valid?
        refute cs_user_error(context, method, :initial_user, is_raise).valid?
        refute cs_user_error(context, method, :unconfirmed_user, is_raise).valid?
        refute cs_user_error(context, method, :blocked_user, is_raise).valid?
        refute cs_user_error(context, method, :admin, is_raise).valid?
      end
    end
  end

  describe "can_?" do
    context "without initial" do
      it "#can_confirm?", context do
        can_confirm?(context)
        assert User.can_confirm?(context[:initial_user]) == false
        assert User.can_confirm?(context[:not_found_state]) == false
      end

      it "#can_firm?", context do
        can_firm?(context)
        assert User.can_firm?(context[:initial_user]) == false
        assert User.can_firm?(context[:not_found_state]) == false
      end

      it "#can_block?", context do
        can_block?(context)
        assert User.can_block?(context[:initial_user]) == false
        assert User.can_block?(context[:not_found_state]) == false
      end

      it "#can_ck?", context do
        can_ck?(context)
        assert User.can_ck?(context[:initial_user]) == false
        assert User.can_ck?(context[:not_found_state]) == false
      end

      it "#can_make_admin?", context do
        can_make_admin?(context)
        assert User.can_make_admin?(context[:initial_user]) == false
        assert User.can_make_admin?(context[:not_found_state]) == false
      end

      it "#can_make_min?", context do
        can_make_min?(context)
        assert User.can_make_min?(context[:initial_user]) == false
        assert User.can_make_min?(context[:not_found_state]) == false
      end
    end

    context "with initial" do
      it "#can_confirm?", context do
        can_confirm?(context, UserWithInitial)
        assert UserWithInitial.can_confirm?(context[:initial_user]) == false
        assert UserWithInitial.can_confirm?(context[:not_found_state]) == false
      end

      it "#can_firm?", context do
        can_firm?(context, UserWithInitial)
        assert UserWithInitial.can_firm?(context[:initial_user]) == false
        assert UserWithInitial.can_firm?(context[:not_found_state]) == false
      end

      it "#can_block?", context do
        can_block?(context, UserWithInitial)
        assert UserWithInitial.can_block?(context[:initial_user]) == true
        assert UserWithInitial.can_block?(context[:not_found_state]) == true
      end

      it "#can_ck?", context do
        can_ck?(context, UserWithInitial)
        assert UserWithInitial.can_ck?(context[:initial_user]) == true
        assert UserWithInitial.can_ck?(context[:not_found_state]) == true
      end

      it "#can_make_admin?", context do
        can_make_admin?(context, UserWithInitial)
        assert UserWithInitial.can_make_admin?(context[:initial_user]) == false
        assert UserWithInitial.can_make_admin?(context[:not_found_state]) == false
      end

      it "#can_make_min?", context do
        can_make_min?(context, UserWithInitial)
        assert UserWithInitial.can_make_min?(context[:initial_user]) == false
        assert UserWithInitial.can_make_min?(context[:not_found_state]) == false
      end
    end

    defp can_confirm?(context, model \\ User) do
      assert model.can_confirm?(context[:unconfirmed_user]) == true
      assert model.can_confirm?(context[:confirmed_user])   == false
      assert model.can_confirm?(context[:blocked_user])     == false
      assert model.can_confirm?(context[:admin])            == false
    end

    defp can_firm?(context, model \\ User) do
      assert model.can_firm?(context[:unconfirmed_user]) == true
      assert model.can_firm?(context[:confirmed_user])   == false
      assert model.can_firm?(context[:blocked_user])     == false
      assert model.can_firm?(context[:admin])            == false
    end

    defp can_block?(context, model \\ User) do
      assert model.can_block?(context[:unconfirmed_user]) == false
      assert model.can_block?(context[:confirmed_user])   == true
      assert model.can_block?(context[:blocked_user])     == false
      assert model.can_block?(context[:admin])            == true
    end

    defp can_ck?(context, model \\ User) do
      assert model.can_ck?(context[:unconfirmed_user]) == false
      assert model.can_ck?(context[:confirmed_user])   == true
      assert model.can_ck?(context[:blocked_user])     == false
      assert model.can_ck?(context[:admin])            == true
    end

    defp can_make_admin?(context, model \\ User) do
      assert model.can_make_admin?(context[:unconfirmed_user]) == false
      assert model.can_make_admin?(context[:confirmed_user])   == true
      assert model.can_make_admin?(context[:blocked_user])     == false
      assert model.can_make_admin?(context[:admin])            == false
    end

    defp can_make_min?(context, model \\ User) do
      assert model.can_make_min?(context[:unconfirmed_user]) == false
      assert model.can_make_min?(context[:confirmed_user])   == true
      assert model.can_make_min?(context[:blocked_user])     == false
      assert model.can_make_min?(context[:admin])            == false
    end
  end
end
