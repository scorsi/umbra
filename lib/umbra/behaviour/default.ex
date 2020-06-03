defmodule Umbra.Behaviour.Default do
  @moduledoc """
  This is the default behaviour of `GenServer`.

  It only does `use GenServer` behind the scene.
  """

  defmacro __using__(_) do
    quote location: :keep do
      use GenServer
    end
  end
end
