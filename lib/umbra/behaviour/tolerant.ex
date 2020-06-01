defmodule Umbra.Behaviour.Tolerant do
  @moduledoc """
  Umbra.Behaviour.Tolerant
  """

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour GenServer

      @impl GenServer
      def init(args), do: {:ok, args}

      @impl GenServer
      def terminate(_reason, _state), do: :ok

      @impl GenServer
      def code_change(_old, state, _extra), do: {:ok, state}

      defoverridable [
        init: 1,
        terminate: 2,
        code_change: 3
      ]

      @before_compile GSMacro.Behaviour.Tolerant
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @impl GenServer
      def handle_call(_request, _from, state), do: {:noreply, state}

      @impl GenServer
      def handle_cast(_msg, state), do: {:noreply, state}

      @impl GenServer
      def handle_info(_msg, state), do: {:noreply, state}

      @impl GenServer
      def handle_continue(_msg, state), do: {:noreply, state}
    end
  end
end
