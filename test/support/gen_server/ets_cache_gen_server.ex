#defmodule UmbraTest.Support.GenServer.EtsCacheGenServer do
#  @moduledoc false
#
#  use Umbra.GenServer
#
#  definit state: cache_name do
#    :ets.new(cache_name, [:named_table, :set, :protected])
#    {:ok, cache_name}
#  end
#
#  def get(cache_name, key) do
#    value = case :ets.lookup(cache_name, key) do
#      [{^key, value}] -> value
#      [] -> nil
#    end
#    {:ok, value}
#  end
#
#  def get_or_create(cache_name, key, value) do
#    value = case get(cache_name, key) do
#      nil -> server_get_or_create(cache_name, key, value)
#      existing -> existing
#    end
#    {:ok, value}
#  end
#
#  defcallp server_get_or_create(key, value), state: cache_name do
#    value = case get(cache_name, key) do
#      nil ->
#        store(cache_name, key, value)
#        set(Node.list, cache_name, key, new)
#        new
#
#      existing -> existing
#    end
#    {:ok, value, cache_name}
#  end
#
#  defmulticall set(key, value), state: cache_name do
#    store(cache_name, key, value)
#    {:ok, :ok, cache_name}
#  end
#
#  defp store(cache_name, key, value) do
#    :ets.insert(cache_name, {key, value})
#  end
#
#  defhandleinfo :timeout, do: {:stop, :normal, state}
#  defhandleinfo _, do: {:noreply, state}
#end