defmodule UmbraTest.Behaviour.DefaultBehaviourTest do
  use ExUnit.Case, async: true

  alias UmbraTest.Support.Behaviour.DefaultBehaviour

  setup do
    Process.flag(:trap_exit, true)
    :ok
  end

  test "should have a standard init implementation" do
    {:ok, _} = DefaultBehaviour.start_link(:wow)
  end

  test "call should exit" do
    {:ok, pid} = DefaultBehaviour.start_link(nil)

    :erlang.trace(pid, true, [:receive])

    {
      {%RuntimeError{}, _},
      {GenServer, :call, [^pid, :whatever_call, _]}
    } = catch_exit(GenServer.call(pid, :whatever_call))

    assert_receive {:EXIT, ^pid, _}

    assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, :whatever_call}}
  end

  test "cast should raise" do
    {:ok, pid} = DefaultBehaviour.start_link(nil)

    :erlang.trace(pid, true, [:receive])

    GenServer.cast(pid, :whatever_cast)

    assert_receive {:EXIT, ^pid, _}

    assert_receive {:trace, ^pid, :receive, {:"$gen_cast", :whatever_cast}}
  end
end
