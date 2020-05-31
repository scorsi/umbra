defmodule Umbra.Extension.Registry do
  defmacro __using__(opts) do
    registry = Keyword.get(opts, :registry)
    via_key = Keyword.get(opts, :via_key)

    quote location: :keep do
      @impl Umbra.GenServer
      def __get_process_name__(state) do
        {:ok, {:via, Registry, {unquote(registry), (unquote(via_key)).(state)}}}
      end

      @impl Umbra.GenServer
      def __get_pid__(state) when is_struct(state) do
        try do
          with [{pid, _}] <- Registry.lookup(unquote(registry), (unquote(via_key)).(state)) do
            {:ok, pid}
          else
            [] -> {:error, :process_not_found}
            _ -> {:error, :unknown_error}
          end
        rescue
          ArgumentError -> {:error, :unknown_registry}
        end
      end

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
    end
  end
end