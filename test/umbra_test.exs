defmodule UmbraTest do
  use ExUnit.Case

  doctest Umbra.GenServer
  doctest Umbra.Operations
  doctest Umbra.DefinitionExtractor
  doctest Umbra.CodeGenerator
end
