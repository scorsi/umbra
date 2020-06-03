defmodule Umbra.Behaviour.Tolerant do
  @moduledoc """
  This is the most tolerant `GenServer` implementation.

  It creates fallback for all handlers returning `{:noreply, state}` which doesn't have any effect.

  `GenServer.handle_call/3` returning `:noreply` will timeout the client, to avoid that, you can define your own
  `handle_call` implementation as follow:
  ```
  defcall _, client: false, state: state, do: {:reply, state, state}
  ```
  """

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour GenServer

      @doc false
      @impl GenServer
      def init(args), do: {:ok, args}

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

      @before_compile Umbra.Behaviour.Tolerant
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @doc false
      @impl GenServer
      def handle_call(_request, _from, state), do: {:noreply, state}

      @doc false
      @impl GenServer
      def handle_cast(_msg, state), do: {:noreply, state}

      @doc false
      @impl GenServer
      def handle_info(_msg, state), do: {:noreply, state}

      @doc false
      @impl GenServer
      def handle_continue(_msg, state), do: {:noreply, state}
    end
  end
end
