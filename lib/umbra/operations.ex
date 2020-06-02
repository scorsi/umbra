defmodule Umbra.Operations do
  @moduledoc """
  This modules is the facade for the `Umbra.CodeGenerator` module.

  It defines all macros `definit/2`, `defcall/3`, `defcast/3`, `definfo/3` and `defcontinue/3`.
  """

  alias Umbra.CodeGenerator

  @doc """
  Generate the `GenServer` `c:GenServer.init/1` callback.

  It is server-side only, so no client method will be defined.

  ## Options

  - when: `a statement`
  - state: `a statement`, default to `_state`

  ## Example
  Defining:

      definit state: state, do: {:ok, state}

  Will generate:

      def init(state: state) do
        {:ok, state}
      end

  """
  @spec definit(list(), list()) :: tuple()
  defmacro definit(opts \\ [], body \\ []),
           do: do_def(:init, nil, opts ++ body)

  @doc """
  Generate the `GenServer` `c:GenServer.handle_call/3` callback and
  a client method to call the function through `GenServer.call/2`.

  By default generates the client and server function in public.

  ## Options

  - private: `boolean()`, default to `false`
  - when: `a statement`
  - server: `boolean()`, default to `true`
  - client: `boolean()`, default to `true`
  - state: `a statement`, default to `_state`
  - from: `a statement`, default to `_from`

  ## Example
  Defining:

      defcall {:compute, a, b}, do: {:reply, a + b, nil}

  Will generate:

      def get_state(pid_or_state, a, b) do
        {:ok, GenServer.call(pid_or_state, {:compute, a, b})
      end
      def handle_call({:compute, a, b}, _from, _state) do
        {:reply, a + b, nil}
      end

  """
  @spec defcall(atom() | tuple(), list(), list()) :: tuple()
  defmacro defcall(definition, opts \\ [], body \\ []),
           do: do_def(:call, definition, opts ++ body)

  @doc """
  Generate the `GenServer` `c:GenServer.handle_cast/2` callback and
  a client method to call the function through `GenServer.cast/2`.

  By default generates the client and server function in public.

  ## Options

  - private: `boolean()`, default to `false`
  - when: `a statement`
  - server: `boolean()`, default to `true`
  - client: `boolean()`, default to `true`
  - state: `a statement`, default to `_state`

  ## Example

  Defining:

      defcast {:set_state, %{id: id, name: name} = new_state}, do: {:noreply, new_state}

  Will generate:

      def set_state(pid, %{id: _id, name: _name} = new_state) do
        GenServer.cast(pid, {:set_state, new_state})
      end
      def handle_cast({:set_state, %{id: id, name: name} = new_state}, _state) do
        {:noreply, new_state}
      end

  """
  @spec defcast(atom() | tuple(), list(), list()) :: tuple()
  defmacro defcast(definition, opts \\ [], body \\ []),
           do: do_def(:cast, definition, opts ++ body)

  @doc """
  Generate the `GenServer` `c:GenServer.handle_info/2` callback and
  a client method to call the function through `Process.send/3`.

  By default only generate the server-side function.
  The client-side function can be useful sometimes.

  ## Options

  - private: `boolean()`, default to `false`
  - when: `a statement`
  - server: `boolean()`, default to `true`
  - client: `boolean()`, default to `false`
  - state: `a statement`, default to `_state`

  ## Example

  Defining:

      definfo {:ping}, client: true, state: state do
        IO.puts(:pong)
        {:noreply, state}
      end

  Will generate:

      def ping(pid) do
        Process.send(pid, {:ping})
      end
      def handle_info({:ping}, state) do
        IO.puts(:pong)
        {:noreply, state}
      end

  """
  @spec definfo(atom() | tuple(), list(), list()) :: tuple()
  defmacro definfo(definition, opts \\ [], body \\ []),
           do: do_def(:info, definition, opts ++ body)

  @doc """
  Generate the `GenServer` `c:GenServer.handle_continue/2` callback.

  It is server-side only, so no client method will be defined.

  ## Options

  - when: `a statement`
  - state: `a statement`, default to `_state`

  ## Example
  Defining:

      defcontinue {:send_to_process, pid, result}, state: state do
        Process.send(pid, result)
        {:noreply, state}
      end

  Will generate:

      def handle_continue({:send_to_process, pid, result}, state) do
        Process.send(pid, result)
        {:noreply, state}
      end

  """
  @spec defcontinue(atom() | tuple(), list(), list()) :: tuple()
  defmacro defcontinue(definition, opts \\ [], body \\ []),
           do: do_def(:continue, definition, opts ++ body)

  @doc """
  Only used to reduce code duplication
  """
  @spec do_def(atom(), tuple(), list()) :: tuple()
  defp do_def(type, definition, options),
       do: generate(type, definition, options(type, options))

  @doc """
  Generate client and server function in the module thanks to the `Umbra.CodeGenerator` module.

  Must be called from a macro.
  """
  @spec generate(atom(), atom() | tuple(), list()) :: tuple()
  defp generate(type, definition, opts)

  defp generate(type, def, opts) do
    functions =
      [
        (if Keyword.get(opts, :client), do: CodeGenerator.generate_client_function(type, def, opts)),
        (if Keyword.get(opts, :server), do: CodeGenerator.generate_server_function(type, def, opts))
      ]
      |> Enum.filter(&(!is_nil(&1)))

    if Enum.empty?(functions) do
      raise(ArgumentError, message: "at least one function should be defined, server or client side.")
    end

    functions
    |> CodeGenerator.add_to_module()
  end

  @doc """
  Checks the options depending of the handler type.

  If invalid options are passed, raise an error.
  """
  @spec options(atom(), list()) :: list()
  defp options(type, options)

  defp options(:init, opts) do
    KeywordValidator.validate!(
      opts,
      %{
        server: [
          type: :boolean,
          default: true,
          inclusion: [true]
        ],
        when: [],
        state: [],
        do: [
          required: true
        ],
      }
    )
  end
  defp options(:call, opts) do
    KeywordValidator.validate!(
      opts,
      %{
        private: [
          type: :boolean,
          default: false
        ],
        server: [
          type: :boolean,
          default: true
        ],
        client: [
          type: :boolean,
          default: true
        ],
        when: [],
        state: [],
        from: [],
        do: [
          required: true
        ],
      }
    )
  end
  defp options(:cast, opts) do
    KeywordValidator.validate!(
      opts,
      %{
        private: [
          type: :boolean,
          default: false
        ],
        server: [
          type: :boolean,
          default: true
        ],
        client: [
          type: :boolean,
          default: true
        ],
        when: [],
        state: [],
        do: [
          required: true
        ],
      }
    )
  end
  defp options(:info, opts) do
    KeywordValidator.validate!(
      opts,
      %{
        private: [
          type: :boolean,
          default: false
        ],
        server: [
          type: :boolean,
          default: true
        ],
        client: [
          type: :boolean,
          default: false
        ],
        when: [],
        state: [],
        do: [
          required: true
        ],
      }
    )
  end
  defp options(:continue, opts) do
    KeywordValidator.validate!(
      opts,
      %{
        server: [
          type: :boolean,
          default: true,
          inclusion: [true]
        ],
        when: [],
        state: [],
        do: [
          required: true
        ],
      }
    )
  end
end
