defmodule Umbra.Behaviour.Strict do
  @moduledoc false

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour GenServer

      @impl GenServer
      def init(_args), do: {:stop, :badinit}

      @impl GenServer
      def terminate(_reason, _state), do: :ok

      @impl GenServer
      def code_change(_old, state, _extra), do: {:ok, state}

      defoverridable [
        init: 1,
        terminate: 2,
        code_change: 3
      ]

      @before_compile GSMacro.Behaviour.Strict
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @impl GenServer
      def handle_call(request, _from, state), do: {:stop, {:bad_call, request}, state}

      @impl GenServer
      def handle_cast(msg, state), do: {:stop, {:bad_cast, msg}, state}

      @impl GenServer
      def handle_info(msg, state), do: {:stop, {:bad_info, msg}, state}

      @impl GenServer
      def handle_continue(msg, state), do: {:stop, {:bad_continue, msg}, state}
    end
  end
end