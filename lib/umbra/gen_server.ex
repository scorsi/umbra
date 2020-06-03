defmodule Umbra.GenServer do
  @moduledoc """
  The `Umbra.GenServer` is the only module users should care.

  You only need to use that module to get started.
  `Umbra.Operations` is include behind the scene to adds macros and so function generators.

  Example:
  ```
  defmodule MyGenServer do
    use Umbra.GenServer

    # your code
  end
  ```

  You can use Behaviours to override the default `Umbra.GenServer` behaviour :
  - `Umbra.Behaviour.Default` which is used by default.
  - `Umbra.Behaviour.Strict`.
  - `Umbra.Behaviour.Tolerant`.

  To use a specific Behaviour, you can do:
  ```
  defmodule MyGenServer do
    use Umbra.GenServer,
      behaviour: Umbra.GenServer.Tolerant
  end
  ```

  Umbra is overridable by [callbacks](#callbacks), but you should use it at your own depends.

  You can also use Extensions to modify the behaviour of your GenServer :
  - `Umbra.Extension.NameSetter`
  - `Umbra.Extension.Registry`
  """

  @doc """
  This callback is used behind the scene by Umbra to start the `GenServer` and
  can be overrided by extensions or user when needed.

  It's here to allow user/extensions to modify the options passed to `GenServer`.

  It's a callback which only should be override! You should call `super(linked, state, opts)`
  at the end of your own implementation.

  Example:
  ```
  defmodule MyGenServer do
    use Umbra.GenServer

    def __start__(linked, state, opts) do
      {_, opts} = Keyword.pop(opts, :debug)
      opts = opts ++ [debug: [:trace]]
      super(linked, state, opts)
    end
  end
  ```

  The `Umbra.Extension.NameSetter` extension did set a `c:Umbra.GenServer.__start__/3` override to
  automatically set the process name thanks to the `c:Umbra.Extension.NameSetter.__get_process_name__/1` callback.

  Basically this callback only do:
  ```
  GenServer.start(__MODULE__, state, opts) # or start_link if `linked` == true
  ```
  """
  @callback __start__(linked :: boolean(), state :: struct(), opts :: keyword()) :: {:ok, PID.t} | {:error, any()}

  @doc """
  This callback is used to retrieve the `PID.t` from the first argument of each client-side genserver function.

  Without any extensions, only `PID.t` are working.

  The `Umbra.Extension.Registry` extension did set this callback to retrieve the `PID.t` from the GenServer state/struct.
  """
  @callback __get_pid__(pid_or_state :: struct() | PID.t) :: {:ok, PID.t} | {:error, any()}

  @doc """
  This callback is used to do some changement on state or just initialize some stuff for extensions.

  It's a callback which only should be override! You should call `super(state)` when success
  at the end of your own implementation.

  The `Umbra.Extension.Ping` extension did set this callback to initialize itself.
  """
  @callback __init__(state :: struct()) :: {:ok, struct()} | {:error, any()}

  @doc false
  defmacro __using__(opts) do
    behaviour = Keyword.get(opts, :behaviour, Umbra.Behaviour.Default)
    quote location: :keep do
      @behaviour Umbra.GenServer

      use unquote(behaviour)

      import Umbra.Operations

      @doc false
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

      @doc false
      @impl Umbra.GenServer
      def __init__(state), do: {:ok, state}

      @doc false
      @impl Umbra.GenServer
      def __get_pid__(pid) when is_pid(pid), do: {:ok, pid}

      @doc false
      def start_link(state, opts \\ []), do: __MODULE__.__start__(true, state, opts)
      @doc false
      def start(state, opts \\ []), do: __MODULE__.__start__(false, state, opts)

      defoverridable [
        __start__: 3,
        __init__: 1,
      ]

      @before_compile Umbra.GenServer
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      @doc false
      @impl Umbra.GenServer
      def __get_pid__(_), do: {:error, :bad_arg}
    end
  end
end
