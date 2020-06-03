defmodule Umbra.BehaviourTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO
  import ExUnit.CaptureLog

  test "default behaviour without init method" do
    capture_io(
      :stderr,
      fn ->
        defmodule Default do
          use Umbra.GenServer
        end

        {:ok, _} = Default.start_link(:wow)
      end
    ) =~ ~r/warning: function init\/1 required by behaviour GenServer is not implemented \(in module Umbra\.BehaviourTest\.Default\)/
  end

  test "explicit default behaviour without init method" do
    capture_io(
      :stderr,
      fn ->
        defmodule ExplicitDefault do
          use Umbra.GenServer,
              behaviour: Umbra.Behaviour.Default
        end

        {:ok, _} = ExplicitDefault.start_link(:wow)
      end
    ) =~ ~r/warning: function init\/1 required by behaviour GenServer is not implemented \(in module Umbra\.BehaviourTest\.ExplicitDefault\)/
  end

  test "strict behaviour should always return badarg on init" do
    defmodule NoInitStrictBehaviour do
      @moduledoc false

      use Umbra.GenServer,
          behaviour: Umbra.Behaviour.Strict
    end

    assert NoInitStrictBehaviour.start_link(nil) == {:error, :badinit}
    assert NoInitStrictBehaviour.start_link(42) == {:error, :badinit}
    assert NoInitStrictBehaviour.start_link(:something_else) == {:error, :badinit}
  end

  test "strict behaviour with init should always throw on call, cast and info" do
    defmodule WithInitStrictBehaviour do
      @moduledoc false

      use Umbra.GenServer,
          behaviour: Umbra.Behaviour.Strict

      definit state: state, do: {:ok, state}
    end

    {:ok, pid} = WithInitStrictBehaviour.start(nil)
    fun = fn ->
      Task.start(fn -> GenServer.call(pid, :whatever_call) end)
      Process.sleep(200)
    end
    assert capture_log(fun) =~ ~r/\*\* \(stop\) bad call: :whatever_call/u

    {:ok, pid} = WithInitStrictBehaviour.start(nil)
    fun = fn ->
      Task.start(fn -> GenServer.cast(pid, :whatever_cast) end)
      Process.sleep(200)
    end
    assert capture_log(fun) =~ ~r/\*\* \(stop\) bad cast: :whatever_cast/u

    {:ok, pid} = WithInitStrictBehaviour.start(nil)
    fun = fn ->
      Task.start(fn -> Process.send(pid, :whatever_info, []) end)
      Process.sleep(200)
    end
    assert capture_log(fun) =~ ~r/\*\* \(stop\) {:bad_info, :whatever_info}/u
  end

  test "tolerant behaviour should always respond noreply" do
    defmodule TolerantBehaviour do
      @moduledoc false

      use Umbra.GenServer,
          behaviour: Umbra.Behaviour.Tolerant
    end

    {:ok, pid} = TolerantBehaviour.start(nil)
    fun = fn ->
      Task.start(fn -> GenServer.call(pid, :whatever_call, 200) end)
      Process.sleep(500)
    end
    assert capture_log(fun) =~ ~r/\*\* \(stop\) exited in: GenServer\.call\(#PID<\d+\.\d+\.\d+>, :whatever_call, \d+\)/

    {:ok, pid} = TolerantBehaviour.start(nil)
    fun = fn ->
      Task.start(fn -> GenServer.cast(pid, :whatever_cast) end)
      Process.sleep(200)
    end
    assert capture_log(fun) == ""

    {:ok, pid} = TolerantBehaviour.start(nil)
    fun = fn ->
      Task.start(fn -> Process.send(pid, :whatever_info, []) end)
      Process.sleep(200)
    end
    assert capture_log(fun) == ""
  end
end