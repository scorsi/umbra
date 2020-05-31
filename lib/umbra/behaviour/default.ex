defmodule Umbra.Behaviour.Default do
  @moduledoc false

  defmacro __using__(_) do
    quote location: :keep do
      use GenServer
    end
  end
end