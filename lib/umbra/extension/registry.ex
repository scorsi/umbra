defmodule Umbra.Extension.Registry do
  @moduledoc """
  The `Umbra.Extension.Registry` extension allow user to use a `Registry` under the hood and automatically use the state
  to retrieve the `Registry` `via_name` tuple.

  Warning, it directly depends of the `Umbra.Extension.NameSetter` extension.
  You have to use it before using this extension.

  This extension requires defining a struct for your state.

  You shall define your `Registry` under a `Supervisor` tree.

  Example:
  ```
  defmodule MyGenServer do
    defstruct [:id, :other_states]

    use Umbra.GenServer
    use Umbra.Extension.NameSetter
    use Umbra.Extension.Registry,
      registry: MyRegistry,
      via_key: fn %__MODULE__{id: id} -> id end

    # your code
  end

  # Start your Registry before trying to use the GenServer
  {:ok, _} = Registry.start_link(keys: :unique, name: MyRegistry)

  # Declare the state and start the GenServer with it
  state = %MyGenServer{
    id: 2,
    data: 3
  }
  {:ok, _} = MyGenServer.start_link(state)

  # You can use your GenServer directly with your struct instead of the PID
  state
  |> MyGenServer.do_something(state)
  ```
  """

  @doc false
  defmacro __using__(opts) do
    KeywordValidator.validate!(
      opts,
      %{
        registry: [
          type: [:module, :atom, :tuple], # add tuple to cheat macros
          required: true
        ],
        via_key: [
          type: [{:function, 1}, :tuple], # add tuple to cheat macros
          required: true
        ]
      }
    )

    registry = Keyword.get(opts, :registry)
    via_key = Keyword.get(opts, :via_key)

    quote location: :keep do
      @doc false
      @impl Umbra.Extension.NameSetter
      def __get_process_name__(%{} = state) do
        {:ok, {:via, Registry, {unquote(registry), (unquote(via_key)).(state)}}}
      end

      @doc false
      @impl Umbra.GenServer
      def __get_pid__(%{} = state) do
        case Registry.lookup(unquote(registry), (unquote(via_key)).(state)) do
          [{pid, _}] -> {:ok, pid}
          [] -> {:error, :process_not_found}
          _ -> {:error, :unknown_error}
        end
      rescue
        ArgumentError -> {:error, :unknown_registry}
      end
    end
  end
end
