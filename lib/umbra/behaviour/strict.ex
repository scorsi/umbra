defmodule Umbra.Behaviour.Strict do
  @moduledoc """
  This Behaviour does't let any possibility of mistakes.

  It defines :
  - init returning `{:stop, :badinit}`
  - all handlers fallback returning `{:stop, {:bad_*, msg}, state}`
  """

  @doc false
  defmacro __using__(_) do
    quote location: :keep do
      @behaviour GenServer

      @doc false
      @impl GenServer
      def init(_args), do: {:stop, :badinit}

      @doc false
      @impl GenServer
      def terminate(_reason, _state), do: :ok

      @doc false
      @impl GenServer
      def code_change(_old, state, _extra), do: {:ok, state}

      defoverridable [
        init: 1,
        terminate: 2,
        code_change: 3
      ]

      @before_compile Umbra.Behaviour.Strict
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      @doc false
      @impl GenServer
      def handle_call(request, _from, state), do: {:stop, {:bad_call, request}, state}

      @doc false
      @impl GenServer
      def handle_cast(msg, state), do: {:stop, {:bad_cast, msg}, state}

      @doc false
      @impl GenServer
      def handle_info(msg, state), do: {:stop, {:bad_info, msg}, state}

      @doc false
      @impl GenServer
      def handle_continue(msg, state), do: {:stop, {:bad_continue, msg}, state}
    end
  end
end
