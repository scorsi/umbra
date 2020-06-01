defmodule UmbraTest.GenServer.BasicGenServerTest do
  use ExUnit.Case, async: true

  alias UmbraTest.Support.GenServer.BasicGenServer

  test "get_state call" do
    {:ok, pid} = BasicGenServer.start_link(0)

    :erlang.trace(pid, true, [:receive])

    assert {:ok, 0} == BasicGenServer.get_state(pid)
    assert 0 == :sys.get_state(pid)

    assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, {:get_state}}}
  end

  test "set_state call" do
    {:ok, pid} = BasicGenServer.start_link(0)

    :erlang.trace(pid, true, [:receive])

    assert {:ok, 0} == BasicGenServer.get_state(pid)
    assert :ok == BasicGenServer.set_state(pid, 42)
    assert {:ok, 42} == BasicGenServer.get_state(pid)

    assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, {:get_state}}}
    assert_receive {:trace, ^pid, :receive, {:"$gen_cast", {:set_state, 42}}}
    assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, {:get_state}}}
  end

  test "increment and decrement call" do
    {:ok, pid} = BasicGenServer.start_link(0)

    :erlang.trace(pid, true, [:receive])

    assert :ok == BasicGenServer.increment(pid)
    assert {:ok, 1} == BasicGenServer.get_state(pid)

    assert_receive {:trace, ^pid, :receive, {:"$gen_cast", {:increment}}}
    assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, {:get_state}}}

    assert :ok == BasicGenServer.increment(pid)
    assert {:ok, 2} == BasicGenServer.get_state(pid)

    assert_receive {:trace, ^pid, :receive, {:"$gen_cast", {:increment}}}
    assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, {:get_state}}}

    assert :ok == BasicGenServer.decrement(pid)
    assert {:ok, 1} == BasicGenServer.get_state(pid)

    assert_receive {:trace, ^pid, :receive, {:"$gen_cast", {:decrement}}}
    assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, {:get_state}}}

    assert :ok == BasicGenServer.decrement(pid)
    assert {:ok, 0} == BasicGenServer.get_state(pid)

    assert_receive {:trace, ^pid, :receive, {:"$gen_cast", {:decrement}}}
    assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, {:get_state}}}

    assert :ok == BasicGenServer.decrement(pid)
    assert {:ok, -1} == BasicGenServer.get_state(pid)

    assert_receive {:trace, ^pid, :receive, {:"$gen_cast", {:decrement}}}
    assert_receive {:trace, ^pid, :receive, {:"$gen_call", _, {:get_state}}}
  end
end
