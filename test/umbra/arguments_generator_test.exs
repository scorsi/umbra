defmodule UmbraTest.ArgumentsGeneratorTest do
  use ExUnit.Case, async: false
  use Quixir

  alias Umbra.DefinitionExtractor
  alias Umbra.ArgumentsGenerator

  @tag timeout: :infinity
  test "no options should always return the unmodifed ast" do
    ptest [arguments: Generator.generate_random_arguments()], repeat_for: 2000 do
      assert arguments == ArgumentsGenerator.generate_arguments(arguments)
    end
  end

  test "options [unshadow: true, assignments: false, optimizations: true] is ok" do
    [
      %{
        definition:
          quote do
            {:a, a, _c}
          end,
        expect: [
          {:a, '', UmbraTest.ArgumentsGeneratorTest},
          {:c, '', UmbraTest.ArgumentsGeneratorTest}
        ]
      },
      %{
        definition:
          quote do
            {:a, 3 = _c}
          end,
        expect: [
          {:c, '', UmbraTest.ArgumentsGeneratorTest}
        ]
      },
      %{
        definition:
          quote do
            {:a, [head | tail], 42 = a}
          end,
        expect: [{:umbra_var_1, '', nil}, {:a, '', UmbraTest.ArgumentsGeneratorTest}]
      },
      %{
        definition:
          quote do
            {:a, %{something: true}}
          end,
        expect: [{:umbra_var_1, '', nil}]
      }
    ]
    |> Enum.each(
         fn %{definition: definition, expect: expect} ->
           result =
             definition
             |> DefinitionExtractor.extract_arguments_from_definition()
             |> ArgumentsGenerator.generate_arguments(
                  unshadow: true,
                  assignments: false,
                  optimizations: true
                )

           assert expect == result
         end
       )
  end

  test "options [unshadow: true, shadow: true, optimizations: true] is ok" do
    [
      %{
        definition:
          quote do
            {:a, a, _c}
          end,
        expect: [{:a, '', __MODULE__}, {:c, '', __MODULE__}]
      },
      %{
        definition:
          quote do
            {:a, [head | tail], 42 = a}
          end,
        expect: [
          {
            :=,
            [],
            [
              [
                {
                  :|,
                  [],
                  [
                    {:_head, [], UmbraTest.ArgumentsGeneratorTest},
                    {:_tail, [], UmbraTest.ArgumentsGeneratorTest}
                  ]
                }
              ],
              {:umbra_var_1, [], nil}
            ]
          },
          {:=, '', [42, {:a, '', UmbraTest.ArgumentsGeneratorTest}]}
        ]
      },
      %{
        definition:
          quote do
            {:a, 3 = _c}
          end,
        expect: [
          {:=, '', [3, {:c, '', UmbraTest.ArgumentsGeneratorTest}]}
        ]
      },
      %{
        definition:
          quote do
            {:a, %{something: true, name: _name, id: id}}
          end,
        expect: [
          {
            :=,
            '',
            [
              {
                :%{},
                [],
                [
                  something: true,
                  name: {:_name, [], UmbraTest.ArgumentsGeneratorTest},
                  id: {:_id, [], UmbraTest.ArgumentsGeneratorTest}
                ]
              },
              {:umbra_var_1, [], nil}
            ]
          }
        ]
      },
      %{
        definition:
          quote do
            {:a, %{name: "John", lastname: "Do", age: age} = user}
          end,
        expect: [
          {
            :=,
            [],
            [
              {:%{}, [], [name: "John", lastname: "Do", age: {:_age, [], __MODULE__}]},
              {:user, [], __MODULE__}
            ]
          }
        ]
      },
      %{
        definition:
          quote do
            {:a, <<127 :: rest>> = payload}
          end,
        expect: [
          {
            :=,
            [],
            [
              {:<<>>, [], [{:"::", [], [127, {:_rest, [], UmbraTest.ArgumentsGeneratorTest}]}]},
              {:payload, [], UmbraTest.ArgumentsGeneratorTest}
            ]
          }
        ]
      },
      %{
        definition:
          quote do
            {:a, [1, 2, 3]}
          end,
        expect: [
          {:=, [], [[1, 2, 3], {:umbra_var_1, [], nil}]}
        ]
      }
    ]
    |> Enum.each(
         fn %{definition: definition, expect: expect} ->
           result =
             definition
             |> DefinitionExtractor.extract_arguments_from_definition()
             |> ArgumentsGenerator.generate_arguments(
                  unshadow: true,
                  shadow: true,
                  optimizations: true
                )

           assert expect == result
         end
       )
  end
end
