defmodule UmbraTest.Support.Extension.NameSetterExtension do
  use Umbra.GenServer
  use Umbra.Extension.NameSetter

  @impl Umbra.Extension.NameSetter
  def __get_process_name__(%{name: name}) do
    {:ok, name}
  end

  definit state: state, do: {:ok, state}

  defcall {:get_val}, state: %{val: val} = state, do: {:reply, val, state}
end