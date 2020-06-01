defmodule UmbraTest.Support.GenServer.BasicGenServer do
  @moduledoc false

  use Umbra.GenServer

  definit do: {:ok, state}

  defcall {:get_state}, do: {:reply, state, state}

  defcast {:set_state, new_state}, do: {:noreply, new_state}

  defcast {:increment}, state: state, do: {:noreply, state + 1}

  defcast {:decrement}, state: state, do: {:noreply, state - 1}
end
