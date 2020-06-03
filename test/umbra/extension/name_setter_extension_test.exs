defmodule UmbraTest.Extension.NameSetterExtension do
  use ExUnit.Case

  alias UmbraTest.Support.Extension.NameSetterExtension

  test "name should be set" do
    {:ok, _} = NameSetterExtension.start_link(%{name: :toto, val: 42})
    {:ok, 42} = NameSetterExtension.get_val(:toto)

    {:ok, _} = NameSetterExtension.start_link(%{name: :toto2, val: -512})
    {:ok, -512} = NameSetterExtension.get_val(:toto2)
  end
end