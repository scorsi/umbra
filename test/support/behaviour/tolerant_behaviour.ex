defmodule UmbraTest.Support.Behaviour.TolerantBehaviour do
  @moduledoc false

  use Umbra.GenServer,
      behaviour: Umbra.Behaviour.Tolerant
end
