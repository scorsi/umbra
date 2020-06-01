defmodule Umbra.GenServer do
  @moduledoc """
  Umbra.GenServer
  """

  @callback __start__(linked :: boolean(), state :: struct(), opts :: keyword()) :: {:ok, PID.t} | {:error, any()}
  @callback __get_pid__(pid_or_state :: struct() | PID.t) :: {:ok, PID.t} | {:error, any()}
  @callback __get_process_name__(state :: struct()) :: {:ok, any()} | {:error, any()}

  defmacro __using__(opts) do
    behaviour = generate_behaviour(Keyword.get(opts, :behaviour, Umbra.Behaviour.Default))
    quote location: :keep do
      @behaviour Umbra.GenServer

      unquote(behaviour)

      import Umbra.Operations

      @impl Umbra.GenServer
      def __start__(linked, state, opts) do
        if linked do
          GenServer.start_link(__MODULE__, state, opts)
        else
          GenServer.start(__MODULE__, state, opts)
        end
      rescue
        e in ArgumentError ->
          case e.message do
            "unknown registry" <> _ -> {:error, :unknown_registry}
            _ -> {:error, {:unknown_error, e}}
          end
        e -> {:error, {:unknown_error, e}}
      end

      @impl Umbra.GenServer
      def __get_pid__(pid) when is_pid(pid), do: {:ok, pid}

      def start_link(state, opts \\ []), do: __MODULE__.__start__(true, state, opts)
      def start(state, opts \\ []), do: __MODULE__.__start__(false, state, opts)

      defoverridable [
        __start__: 3,
      ]

      @before_compile Umbra.GenServer
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      @impl Umbra.GenServer
      def __get_pid__(_), do: {:error, :bad_arg}

      @impl Umbra.GenServer
      def __get_process_name__(_), do: {:ok, nil}
    end
  end

  defp generate_behaviour(behaviour) do
    quote do
      use unquote(behaviour)
    end
  end
end
