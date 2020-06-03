defmodule Umbra.RegistryExtensionTest do
  use ExUnit.Case, async: true

  test "should recover pid from state" do
    defmodule ASimpleRegistryGenServer do
      defstruct [:id, :name]

      use Umbra.GenServer, behaviour: Umbra.Behaviour.Tolerant
      use Umbra.Extension.NameSetter
      use Umbra.Extension.Registry,
          registry: MyRegistryForTest,
          via_key: fn %{id: id} -> id end

      defcall {:get_name}, state: %{name: name} = state, do: {:reply, name, state}
    end

    {:ok, _} = Registry.start_link(keys: :unique, name: MyRegistryForTest)

    state = %{id: 523, name: "yeah"}
    {:ok, _} = ASimpleRegistryGenServer.start_link(state)

    {:ok, "yeah"} = ASimpleRegistryGenServer.get_name(state)

    state = %{id: 27462, name: "other one"}
    {:ok, _} = ASimpleRegistryGenServer.start_link(state)
    {:ok, "other one"} = ASimpleRegistryGenServer.get_name(state)
  end

  test "invalid registry options" do
    assert catch_error(
      defmodule OopsRegistryGenServer do
        defstruct [:id, :name]

        use Umbra.GenServer, behaviour: Umbra.Behaviour.Tolerant
        use Umbra.Extension.NameSetter
        use Umbra.Extension.Registry,
            via_key: fn %{id: id} -> id end

        defcall {:get_name}, state: %{name: name} = state, do: {:reply, name, state}
      end
    )

    assert catch_error(
             defmodule OopsRegistryGenServer do
               defstruct [:id, :name]

               use Umbra.GenServer, behaviour: Umbra.Behaviour.Tolerant
               use Umbra.Extension.NameSetter
               use Umbra.Extension.Registry,
                   registry: :my_registry

               defcall {:get_name}, state: %{name: name} = state, do: {:reply, name, state}
             end
           )
  end
end