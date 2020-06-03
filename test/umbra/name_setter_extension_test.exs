defmodule Umbra.NameSetterExtensionTest do
  use ExUnit.Case, async: true

  test "name should be set" do
    defmodule SimpleNameSetterExtension do
      use Umbra.GenServer
      use Umbra.Extension.NameSetter

      @impl Umbra.Extension.NameSetter
      def __get_process_name__(%{name: name}) do
        {:ok, name}
      end

      definit state: state, do: {:ok, state}

      defcall {:get_val}, state: %{val: val} = state, do: {:reply, val, state}
    end

    {:ok, _} = SimpleNameSetterExtension.start_link(%{name: :toto, val: 42})
    {:ok, 42} = SimpleNameSetterExtension.get_val(:toto)

    {:ok, _} = SimpleNameSetterExtension.start_link(%{name: :toto2, val: -512})
    {:ok, -512} = SimpleNameSetterExtension.get_val(:toto2)
  end
end