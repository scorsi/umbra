defmodule Umbra.Behaviour.Default do
  @moduledoc """
  Umbra.Behaviour.Default
  """

  defmacro __using__(_) do
    quote location: :keep do
      use GenServer
    end
  end
end
