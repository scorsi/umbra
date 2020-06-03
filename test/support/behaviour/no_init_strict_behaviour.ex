defmodule UmbraTest.Support.Behaviour.NoInitStrictBehaviour do
  @moduledoc false

  use Umbra.GenServer,
      behaviour: Umbra.Behaviour.Strict
end
