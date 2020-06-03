defmodule UmbraTest.Behaviour.TolerantBehaviourTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias UmbraTest.Support.Behaviour.TolerantBehaviour

  test "should have a standard init implementation" do
    {:ok, _} = TolerantBehaviour.start_link(:wow)
  end

  test "call should timeout" do
    {:ok, pid} = TolerantBehaviour.start(nil)

    fun = fn ->
      Task.start(fn -> GenServer.call(pid, :whatever_call, 200) end)
      Process.sleep(500)
    end

    assert capture_log(fun) =~ ~r/\*\* \(stop\) exited in: GenServer\.call\(#PID<\d+\.\d+\.\d+>, :whatever_call, \d+\)/
  end

  test "cast should run perfectly" do
    {:ok, pid} = TolerantBehaviour.start(nil)

    fun = fn ->
      Task.start(fn -> GenServer.cast(pid, :whatever_cast) end)
      Process.sleep(500)
    end

    assert capture_log(fun) == ""
  end

  test "info should run perfectly" do
    {:ok, pid} = TolerantBehaviour.start(nil)

    fun = fn ->
      Task.start(fn -> Process.send(pid, :whatever_info, []) end)
      Process.sleep(500)
    end

    assert capture_log(fun) == ""
  end
end
