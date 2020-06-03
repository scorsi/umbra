defmodule UmbraTest.Behaviour.DefaultBehaviourTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias UmbraTest.Support.Behaviour.DefaultBehaviour

  test "should have a standard init implementation" do
    {:ok, _} = DefaultBehaviour.start_link(:wow)
  end

  test "call should exit" do
    {:ok, pid} = DefaultBehaviour.start(nil)

    fun = fn ->
      Task.start(fn -> GenServer.call(pid, :whatever_call) end)
      Process.sleep(500)
    end

    assert capture_log(fun) =~ ~r/\*\* \(RuntimeError\) attempted to call GenServer #PID<\d+\.\d+\.\d+> but no handle_call\/3 clause was provided/u
  end

  test "cast should exit" do
    {:ok, pid} = DefaultBehaviour.start(nil)

    fun = fn ->
      Task.start(fn -> GenServer.cast(pid, :whatever_cast) end)
      Process.sleep(500)
    end

    assert capture_log(fun) =~ ~r/\*\* \(RuntimeError\) attempted to cast GenServer #PID<\d+\.\d+\.\d+> but no handle_cast\/2 clause was provided/u
  end

  test "info should exit" do
    {:ok, pid} = DefaultBehaviour.start(nil)

    fun = fn ->
      Task.start(fn -> Process.send(pid, :whatever_info, []) end)
      Process.sleep(500)
    end

    cond do
      System.version |> Version.match?(">= 1.10.0") ->
        assert capture_log(fun) =~ ~r/\[error\] \[message: :whatever_info, module: UmbraTest\.Support\.Behaviour\.DefaultBehaviour, name: #PID<\d+\.\d+\.\d+>\]/u

      true ->
        assert capture_log(fun) =~ ~r/\[error\] UmbraTest\.Support\.Behaviour\.DefaultBehaviour #PID<\d+\.\d+\.\d+> received unexpected message in handle_info\/2: :whatever_info/u
    end
  end
end
