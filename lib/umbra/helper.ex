defmodule Umbra.Helper do
  @moduledoc """
  This module is used under the hood by all Umbra modules.

  It defines some helpers.
  """

  @doc """
  This macro help know if the given atom is a valid name for functions or variables.
  It should be used in when guards.

  Example:

    iex> Umbra.Helper.var_name?(:toto)
    true

    iex> Umbra.Helper.var_name?(:tata)
    true

    iex> Umbra.Helper.var_name?(:%{})
    false
  """
  defmacro var_name?(arg_name) do
    quote do
      is_atom(unquote(arg_name)) and not (unquote(arg_name) in [
        :_,
        :\\,
        :=,
        :%,
        :%{},
        :{},
        :<<>>,
        :def,
        :defp,
        :defmacro,
        :defmacrop,
        :defmodule,
        :do,
        :use,
        :import,
        :alias,
      ])
    end
  end

  @doc """
  This function is used to extract function name and arguments.

  It returns a tuple with the function name and the arguments.
  When the function did fails, it raises `ArgumentError`.

  Example:

    iex> Umbra.Helper.extract_definition(:get_state)
    {:get_state, []}

    iex> Umbra.Helper.extract_definition(quote do: :get_state)
    {:get_state, []}

    iex> Umbra.Helper.extract_definition(quote do: {:get_state})
    {:get_state, []}

    iex> Umbra.Helper.extract_definition(quote do: get_state())
    {:get_state, []}

    iex> Umbra.Helper.extract_definition(quote do: {:set_state, new_state})
    {:set_state, [:new_state]}

    iex> Umbra.Helper.extract_definition(quote do: set_state(new_state))
    {:set_state, [:new_state]}

    iex> Umbra.Helper.extract_definition(quote do: {:do_something, a, b})
    {:do_something, [:a, :b]}

    iex> Umbra.Helper.extract_definition(quote do: do_something(a, b))
    {:do_something, [:a, :b]}

    iex> Umbra.Helper.extract_definition(quote do: def(a))
    ** (ArgumentError) invalid definition

    iex> Umbra.Helper.extract_definition(quote do: my_func(def))
    ** (ArgumentError) invalid argument

    iex> Umbra.Helper.extract_definition(quote do: my_func(%{something: true}))
    ** (ArgumentError) invalid argument
  """
  @spec extract_definition(definition :: any()) :: {atom(), [atom()]}
  def extract_definition(definition)

  def extract_definition({fun, arg}) when var_name?(fun), do: {fun, [extract_argument(arg)]}
  def extract_definition({fun, _, args}) when var_name?(fun) and is_list(args),
      do: {fun, Enum.map(args, fn arg -> extract_argument(arg) end)}
  def extract_definition({:{}, _, [fun]}) when var_name?(fun), do: {fun, []}
  def extract_definition({:{}, _, [fun | args]}) when var_name?(fun) and is_list(args),
      do: {fun, Enum.map(args, fn arg -> extract_argument(arg) end)}
  def extract_definition(fun) when var_name?(fun), do: {fun, []}
  def extract_definition(_), do: raise(ArgumentError, message: "invalid definition")

  @doc """
  This function is used to extract argument.

  It returns an atom corresponding to the argument name.
  When the function did fails, it raises `ArgumentError`.

  Example:

    iex> Umbra.Helper.extract_argument(:my_arg)
    :my_arg

    iex> Umbra.Helper.extract_argument(quote do: :my_arg)
    :my_arg

    iex> Umbra.Helper.extract_argument(quote do: a_var)
    :a_var

    iex> Umbra.Helper.extract_argument(quote do: :def)
    ** (ArgumentError) invalid argument

    iex> Umbra.Helper.extract_argument(quote do: %{something: true})
    ** (ArgumentError) invalid argument
  """
  @spec extract_argument(argument :: any()) :: atom()
  def extract_argument(argument)

  def extract_argument({arg, _, _}) when var_name?(arg), do: arg
  def extract_argument(arg) when var_name?(arg), do: arg
  def extract_argument(_), do: raise(ArgumentError, message: "invalid argument")
end
