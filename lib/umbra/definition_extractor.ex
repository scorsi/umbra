defmodule Umbra.DefinitionExtractor do
  @moduledoc false

  import Umbra.Helper

  @doc """
  Extract the function name from a function definition.
  """
  @spec extract_function_name_from_definition(definition :: tuple() | atom()) :: atom()
  def extract_function_name_from_definition(definition) do
    do_extract_function_name_from_definition(definition)
  end

  defp do_extract_function_name_from_definition({:{}, _, [fun]})
       when is_atom(fun) and not is_registered_keyword(fun) do
    fun
  end

  defp do_extract_function_name_from_definition({:{}, _, [fun | args]})
       when is_atom(fun) and not is_registered_keyword(fun) and is_list(args) do
    fun
  end

  defp do_extract_function_name_from_definition({fun, arg})
       when is_atom(fun) and not is_registered_keyword(fun) do
    fun
  end

  defp do_extract_function_name_from_definition(fun)
       when is_atom(fun) and not is_registered_keyword(fun) do
    fun
  end

  defp do_extract_function_name_from_definition(other) do
    raise(RuntimeError, message: "invalid definition, got: #{inspect(other)}")
  end

  @doc """
  Extract the arguments from a function definition.
  """
  @spec extract_arguments_from_definition(definition :: tuple() | atom()) :: atom()
  def extract_arguments_from_definition(definition) do
    do_extract_arguments_from_definition(definition)
  end

  defp do_extract_arguments_from_definition({:{}, _, [fun]})
       when is_atom(fun) and not is_registered_keyword(fun) do
    []
  end

  defp do_extract_arguments_from_definition({:{}, _, [fun | args]})
       when is_atom(fun) and not is_registered_keyword(fun) and is_list(args) do
    args
  end

  defp do_extract_arguments_from_definition({fun, arg})
       when is_atom(fun) and not is_registered_keyword(fun) do
    [arg]
  end

  defp do_extract_arguments_from_definition(fun)
       when is_atom(fun) and not is_registered_keyword(fun) do
    []
  end

  defp do_extract_arguments_from_definition(other) do
    raise(RuntimeError, message: "invalid definition, got: #{inspect(other)}")
  end
end
