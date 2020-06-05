defmodule Umbra.GenServerTest do
  use ExUnit.Case

  test "simple incrementer gen server should work" do
    defmodule SimpleIncrementer do
      use Umbra.GenServer

      definit(state: state, do: {:ok, state})

      defcall({:get_state}, state: state, do: {:reply, state, state})

      defcast({:set_state, new_state}, do: {:noreply, new_state})

      defcast({:increment}, state: state, do: {:noreply, state + 1})

      defcast({:decrement}, state: state, do: {:noreply, state - 1})
    end

    {:ok, pid} = SimpleIncrementer.start_link(0)

    :erlang.trace(pid, true, [:receive])

    assert {:ok, 0} == SimpleIncrementer.get_state(pid)
    assert 0 == :sys.get_state(pid)

    assert :ok == SimpleIncrementer.set_state(pid, 42)
    assert 42 == :sys.get_state(pid)

    assert :ok == SimpleIncrementer.set_state(pid, 0)
    assert 0 == :sys.get_state(pid)

    assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, :get_state}}
    assert_receive {:trace, ^pid, :receive, {:"$gen_cast", {:set_state, 42}}}
    assert_receive {:trace, ^pid, :receive, {:"$gen_cast", {:set_state, 0}}}

    assert :ok == SimpleIncrementer.increment(pid)
    assert {:ok, 1} == SimpleIncrementer.get_state(pid)

    assert_receive {:trace, ^pid, :receive, {:"$gen_cast", :increment}}
    assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, :get_state}}

    assert :ok == SimpleIncrementer.increment(pid)
    assert {:ok, 2} == SimpleIncrementer.get_state(pid)

    assert_receive {:trace, ^pid, :receive, {:"$gen_cast", :increment}}
    assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, :get_state}}

    assert :ok == SimpleIncrementer.decrement(pid)
    assert {:ok, 1} == SimpleIncrementer.get_state(pid)

    assert_receive {:trace, ^pid, :receive, {:"$gen_cast", :decrement}}
    assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, :get_state}}

    assert :ok == SimpleIncrementer.decrement(pid)
    assert {:ok, 0} == SimpleIncrementer.get_state(pid)

    assert_receive {:trace, ^pid, :receive, {:"$gen_cast", :decrement}}
    assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, :get_state}}

    assert :ok == SimpleIncrementer.decrement(pid)
    assert {:ok, -1} == SimpleIncrementer.get_state(pid)

    assert_receive {:trace, ^pid, :receive, {:"$gen_cast", :decrement}}
    assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, :get_state}}
  end

  test "def func with guards should be fine" do
    defmodule WithGuards do
      use Umbra.GenServer, behaviour: Umbra.Behaviour.Strict

      definit(state: state, when: is_number(state), do: {:ok, state})

      defcast({:set_state, new_state}, when: is_number(new_state), do: {:noreply, new_state})
      defcall({:do_that, a}, when: a > 0 and a < 10, state: state, do: {:reply, state + a, state})

      defcall({:whats_this?, a}, when: is_number(a), state: state, do: {:reply, :a_number, state})
      defcall({:whats_this?, a}, when: is_atom(a), state: state, do: {:reply, :an_atom, state})
      defcall({:whats_this?, a}, state: state, do: {:reply, {:dont_know, a}, state})
    end

    {:error, {:function_clause, _}} = WithGuards.start(nil)
    {:error, {:function_clause, _}} = WithGuards.start(:this)

    {:ok, pid} = WithGuards.start(42)
    assert 42 == :sys.get_state(pid)

    {:ok, 45} = WithGuards.do_that(pid, 3)

    {:ok, pid} = WithGuards.start(0)
    assert 0 == :sys.get_state(pid)
    :ok = WithGuards.set_state(pid, 2)
    assert 2 == :sys.get_state(pid)

    {:ok, 4} = WithGuards.do_that(pid, 2)
    {:ok, 3} = WithGuards.do_that(pid, 1)
    {:ok, 11} = WithGuards.do_that(pid, 9)

    {:ok, :a_number} = WithGuards.whats_this?(pid, 1)
    {:ok, :an_atom} = WithGuards.whats_this?(pid, :atom)
    {:ok, {:dont_know, %{hello: :world}}} = WithGuards.whats_this?(pid, %{hello: :world})
  end

  test "def private func should be fine" do
    defmodule Privates do
      use Umbra.GenServer

      definit(state: state, do: {:ok, state})

      def get_state(a), do: _get_state(a)

      defcall({:_get_state}, private: true, state: state, do: {:reply, state, state})

      defcast({:set_state, new_state}, private: true, do: {:noreply, new_state})
    end

    {:ok, pid} = Privates.start(:hello_world)
    assert {:ok, :hello_world} = Privates.get_state(pid)
    assert :hello_world == :sys.get_state(pid)

    assert catch_error(Privates._get_state(pid))
    assert catch_error(Privates.set_state(pid, 0))
  end

  test "def server or client side only func should be fine" do
    defmodule ServerClient do
      use Umbra.GenServer

      definit(state: state, do: {:ok, state})

      defcall({:do_a_thing, _a}, server: false)

      defcall({:do_a_thing, a},
        client: false,
        when: a == :wow,
        state: state,
        do: {:reply, :haha, state}
      )

      defcall({:do_a_thing, a},
        client: false,
        when: a == :hum,
        state: state,
        do: {:reply, :yes_ok, state}
      )

      defcall({:do_a_thing, _a}, client: false, state: state, do: {:reply, :what?, state})
    end

    {:ok, pid} = ServerClient.start(:hello_world)

    {:ok, :haha} = ServerClient.do_a_thing(pid, :wow)
    {:ok, :yes_ok} = ServerClient.do_a_thing(pid, :hum)
    {:ok, :what?} = ServerClient.do_a_thing(pid, :oops)
  end

  test "no server and client should raise" do
    assert catch_error(
             defmodule NoServerAndClient do
               use Umbra.GenServer

               defcall({:oops}, server: false, client: false)
             end
           )
  end

  test "no body on server should raise" do
    assert catch_error(
             defmodule NoServerAndClient do
               use Umbra.GenServer

               defcall({:oops})
             end
           )
  end

  test "continue to respond" do
    defmodule ContinueCompute do
      use Umbra.GenServer

      definit(state: state, do: {:ok, state})

      defcast {:do_heavy_computation, a, b}, state: state do
        {:noreply, state, {:continue, {:calcul_it, a, b}}}
      end

      defcontinue({:calcul_it, a, b}, do: {:noreply, a + b})

      defcall {:do_heavy_computation_2, a, b}, state: state do
        {:reply, state, state, {:continue, {:calcul_it_2, a, b}}}
      end

      defcontinue {:calcul_it_2, a, b} do
        Process.sleep(200)
        {:noreply, a + b}
      end
    end

    {:ok, pid} = ContinueCompute.start(nil)
    :ok = ContinueCompute.do_heavy_computation(pid, 1, 2)
    assert 3 == :sys.get_state(pid)

    {:ok, 3} = ContinueCompute.do_heavy_computation_2(pid, 10, 10)
    Process.sleep(500)
    assert 20 == :sys.get_state(pid)
  end

  test "info" do
    defmodule InfoGenServer do
      use Umbra.GenServer

      definit(state: state, do: {:ok, state})

      defcall({:get_state}, state: state, do: {:reply, state, state})

      definfo({:set_state, new_state},
        client: true,
        when: is_number(new_state),
        do: {:noreply, new_state}
      )

      definfo {:ping, pid}, state: state do
        Process.send(pid, :pong, [])
        {:noreply, state}
      end
    end

    {:ok, pid} = InfoGenServer.start(nil)
    {:ok, nil} = InfoGenServer.get_state(pid)
    :ok = InfoGenServer.set_state(pid, 15)
    {:ok, 15} = InfoGenServer.get_state(pid)

    Process.send(pid, {:ping, self()}, [])
    assert_receive :pong
  end
end
