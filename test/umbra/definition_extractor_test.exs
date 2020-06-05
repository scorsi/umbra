defmodule UmbraTest.DefinitionExtractorTest do
  use ExUnit.Case, async: true
  use Quixir

  alias Umbra.DefinitionExtractor

  @tag timeout: :infinity
  test "extract function name on good definition should succeed" do
    ptest [definition: Generator.generate_random_definition()], repeat_for: 2000 do
      definition = Macro.escape(definition)

      function_name =
        case definition do
          f when is_atom(f) -> f
          {f, _} when is_atom(f) -> f
          {:{}, [], [f | _]} when is_atom(f) -> f
        end

      try do
        assert function_name ==
                 DefinitionExtractor.extract_function_name_from_definition(definition)
      rescue
        _ ->
          IO.puts(inspect(definition))
          raise(RuntimeError)
      end
    end
  end

  @tag timeout: :infinity
  test "extract arguments good definition should succeed" do
    ptest [definition: Generator.generate_random_definition()], repeat_for: 2000 do
      definition = Macro.escape(definition)

      arguments =
        case definition do
          f when is_atom(f) -> []
          {f, arg} when is_atom(f) -> [arg]
          {:{}, [], [f | args]} when is_atom(f) -> args
        end

      try do
        assert arguments == DefinitionExtractor.extract_arguments_from_definition(definition)
      rescue
        e ->
          IO.puts(inspect(definition))
          raise(e)
      end
    end
  end

  test "extract function name on bad definition should raise" do
    assert %RuntimeError{message: "invalid definition, got: {:hey, [], []}"} ==
             catch_error(
               DefinitionExtractor.extract_function_name_from_definition(quote(do: hey()))
             )

    assert %RuntimeError{
             message:
               "invalid definition, got: {:hey, [], [{:a, [], UmbraTest.DefinitionExtractorTest}]}"
           } ==
             catch_error(
               DefinitionExtractor.extract_function_name_from_definition(quote(do: hey(a)))
             )

    assert %RuntimeError{
             message:
               "invalid definition, got: {:hey, [], [{:b, [], UmbraTest.DefinitionExtractorTest}, {:c, [], UmbraTest.DefinitionExtractorTest}]}"
           } ==
             catch_error(
               DefinitionExtractor.extract_function_name_from_definition(quote(do: hey(b, c)))
             )

    assert %RuntimeError{message: "invalid definition, got: {:%{}, [], [oops: true]}"} ==
             catch_error(
               DefinitionExtractor.extract_function_name_from_definition(
                 quote(
                   do: %{
                     oops: true
                   }
                 )
               )
             )

    assert %RuntimeError{message: "invalid definition, got: [:one]"} ==
             catch_error(
               DefinitionExtractor.extract_function_name_from_definition(quote(do: [:one]))
             )

    assert %RuntimeError{
             message:
               "invalid definition, got: [:one, {:two, [], UmbraTest.DefinitionExtractorTest}]"
           } ==
             catch_error(
               DefinitionExtractor.extract_function_name_from_definition(quote(do: [:one, two]))
             )
  end

  test "extract arguments on bad definition should raise" do
    assert %RuntimeError{message: "invalid definition, got: {:hey, [], []}"} ==
             catch_error(DefinitionExtractor.extract_arguments_from_definition(quote(do: hey())))

    assert %RuntimeError{
             message:
               "invalid definition, got: {:hey, [], [{:a, [], UmbraTest.DefinitionExtractorTest}]}"
           } ==
             catch_error(DefinitionExtractor.extract_arguments_from_definition(quote(do: hey(a))))

    assert %RuntimeError{
             message:
               "invalid definition, got: {:hey, [], [{:b, [], UmbraTest.DefinitionExtractorTest}, {:c, [], UmbraTest.DefinitionExtractorTest}]}"
           } ==
             catch_error(
               DefinitionExtractor.extract_arguments_from_definition(quote(do: hey(b, c)))
             )

    assert %RuntimeError{message: "invalid definition, got: {:%{}, [], [oops: true]}"} ==
             catch_error(
               DefinitionExtractor.extract_arguments_from_definition(
                 quote(
                   do: %{
                     oops: true
                   }
                 )
               )
             )

    assert %RuntimeError{message: "invalid definition, got: [:one]"} ==
             catch_error(DefinitionExtractor.extract_arguments_from_definition(quote(do: [:one])))

    assert %RuntimeError{
             message:
               "invalid definition, got: [:one, {:two, [], UmbraTest.DefinitionExtractorTest}]"
           } ==
             catch_error(
               DefinitionExtractor.extract_arguments_from_definition(quote(do: [:one, two]))
             )
  end
end
