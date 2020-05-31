defmodule Umbra.Helper do
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

  def extract_definition({fun, arg}) when var_name?(fun), do: {fun, [arg]}
  def extract_definition({fun, _, args}) when var_name?(fun) and is_list(args), do: {fun, args}
  def extract_definition({:{}, _, [fun]}) when var_name?(fun), do: {fun, []}
  def extract_definition({:{}, _, [fun | args]}) when var_name?(fun) and is_list(args), do: {fun, args}
  def extract_definition(fun) when var_name?(fun), do: {fun, []}
  def extract_definition(_), do: raise(ArgumentError, message: "invalid definition")
end