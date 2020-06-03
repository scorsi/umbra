defmodule UmbraTest.Support.Behaviour.StrictBehaviour do
  @moduledoc false

  use Umbra.GenServer,
      behaviour: Umbra.Behaviour.Strict

  definit state: state, do: {:ok, state}
end
