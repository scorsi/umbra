defmodule UmbraTest.Behaviour.StrictBehaviourTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias UmbraTest.Support.Behaviour.NoInitStrictBehaviour
  alias UmbraTest.Support.Behaviour.StrictBehaviour

  test "no init should exit" do
    assert NoInitStrictBehaviour.start_link(nil) == {:error, :badinit}
  end

  test "with init should create" do
    {:ok, pid} = StrictBehaviour.start_link(42)
    Process.sleep(500)
    assert 42 == :sys.get_state(pid)
  end

  test "call should exit" do
    {:ok, pid} = StrictBehaviour.start(nil)

    fun = fn ->
      Task.start(fn -> GenServer.call(pid, :whatever_call) end)
      Process.sleep(500)
    end

    assert capture_log(fun) =~ ~r/\*\* \(stop\) bad call: :whatever_call/u
  end

  test "cast should exit" do
    {:ok, pid} = StrictBehaviour.start(nil)

    fun = fn ->
      Task.start(fn -> GenServer.cast(pid, :whatever_cast) end)
      Process.sleep(500)
    end

    assert capture_log(fun) =~ ~r/\*\* \(stop\) bad cast: :whatever_cast/u
  end

  test "info should exit" do
    {:ok, pid} = StrictBehaviour.start(nil)

    fun = fn ->
      Task.start(fn -> Process.send(pid, :whatever_info, []) end)
      Process.sleep(500)
    end

    assert capture_log(fun) =~ ~r/\*\* \(stop\) {:bad_info, :whatever_info}/u
  end
end
