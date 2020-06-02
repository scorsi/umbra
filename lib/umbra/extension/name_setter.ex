defmodule Umbra.Extension.NameSetter do
  @moduledoc """
  The extension `Umbra.Extension.NameSetter` is used to manage the
  [GenServer name option](https://hexdocs.pm/elixir/GenServer.html#module-name-registration).

  It overrides the `c:Umbra.GenServer.__start__/3` callback to set the process name (only if missing from options)
  before starting the `GenServer`.

  This extension define a callback `c:__get_process_name__/1` to retrieve/set name
  depending of the state when `start_link/2` or `start/2` of your GenServer are called.

  Example:
  ```
  defmodule MyGenServer do
    defstruct [:id, :other_states]

    use Umbra.GenServer
    use Umbra.Extension.NameSetter

    @impl Umbra.Extension.NameSetter
    def __get_process_name__(%__MODULE__{id: id}) do
      {:ok, "MyGenServer::#\{id}"}
    end

    # your code
  end
  ```
  """

  @doc """
  This callback is used to retrieve the process name depending of the parameter.

  It always returns `{:ok, nil}` except if extensions are used.

  The `Umbra.Extension.Registry` extension did set this callback to
  create the process name from the state thanks to a `Registry` (also called a `via_name`).

  You have to take care of the declaration orders.
  """
  @callback __get_process_name__(state :: struct()) :: {:ok, any() | nil} | {:error, any()}

  @doc """
  This macro allow setting an override to the `c:Umbra.GenServer.__start__/3` callback and
  define a `c:__get_process_name__/1` callback fallback thanks to `__before_compile__/1`.
  """
  @doc false
  defmacro __using__(_opts) do
    quote location: :keep do
      @impl Umbra.GenServer
      def __start__(linked, state, opts) do
        opts = case Keyword.pop(opts, :name) do
          {nil, opts} ->
            case __get_process_name__(state) do
              {:ok, name} -> opts ++ [name: name]
              _ -> opts
            end
          {name, opts} -> opts ++ [name: name]
          _ -> opts
        end

        super(linked, state, opts)
      end

      @before_compile Umbra.Extension.NameSetter
    end
  end

  @doc """
  This macro is used to create a fallback for `c:__get_process_name__/1` callback.
  """
  @doc false
  defmacro __before_compile__(_env) do
    quote do
      @impl Umbra.Extension.NameSetter
      def __get_process_name__(_), do: {:ok, nil}
    end
  end
end
