defmodule UmbraTest.HelperTest do
  import Umbra.Helper

  use ExUnit.Case

  test "macro var_name?" do
    assert true == var_name?(:test)
    assert true == var_name?(:another_test)
    assert false == var_name?(:def)
    assert false == var_name?(:defmacro)
    assert false == var_name?(%{})
    assert false == var_name?(%{item: :something})
    assert false == var_name?([])
    assert false == var_name?([1, 2, 3])
    assert false == var_name?([name: :a_value])
    assert false == var_name?(
             quote do
               def a_function, do: :nothing
             end
           )
  end

  test "function extract_definition" do
    assert {:awesome, []} = extract_definition(
             quote do
               :awesome
             end
           )
    assert {:my_func, []} = extract_definition(
             quote do
               my_func()
             end
           )
    assert {:my_func_another_func, []} = extract_definition(
             quote do
               {:my_func_another_func}
             end
           )
    assert {:my_func, [{:arg1, _, _}]} = extract_definition(
             quote do
               {:my_func, arg1}
             end
           )
    assert {:my_func_bis, [{:arg1, _, _}]} = extract_definition(
             quote do
               my_func_bis(arg1)
             end
           )
    assert {:wow, [{:arg1, _, _}, {:arg2, _, _}]} = extract_definition(
             quote do
               {:wow, arg1, arg2}
             end
           )
    assert {:get_state, [{:arg1, _, _}, {:arg2, _, _}]} = extract_definition(
             quote do
               get_state(arg1, arg2)
             end
           )
    assert_raise ArgumentError, fn -> extract_definition(
                                        quote do
                                          def a_function(a_arg), do: :nothing
                                        end
                                      )
    end
    assert_raise ArgumentError, fn -> extract_definition(
                                        quote do
                                          %{oops: true}
                                        end
                                      )
    end
    assert_raise ArgumentError, fn -> extract_definition(
                                        quote do
                                          [:func]
                                        end
                                      )
    end
    assert_raise ArgumentError, fn -> extract_definition(
                                        quote do
                                          [:func, :arg]
                                        end
                                      )
    end
  end
end
