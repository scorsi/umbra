defmodule Umbra.Helper do
  @moduledoc false

  defmacro is_registered_keyword(atom) do
    quote do
      is_atom(unquote(atom)) and
        unquote(atom) in [
          :def,
          :defp,
          :defmodule,
          :defmacro,
          :defmacrop
        ]
    end
  end

  defmacro is_supported_op(op) do
    quote do
      is_atom(unquote(op)) and
        unquote(op) in [
          :|,
          :<>,
          :"::"
        ]
    end
  end

  defmacro is_unsupported_op(op) do
    quote do
      is_atom(unquote(op)) and
        unquote(op) in [
          :@,
          :.,
          :~~~,
          :not,
          :^,
          :!,
          :-,
          :+,
          :/,
          :*,
          :--,
          :++,
          :^^^,
          :"not in",
          :in,
          :<|>,
          :<~>,
          :~>,
          :<~,
          :~>>,
          :<<~,
          :>>>,
          :<<<,
          :|>,
          :>=,
          :<=,
          :>,
          :<,
          :!==,
          :===,
          :=~,
          :!=,
          :==,
          :and,
          :&&&,
          :&&,
          :or,
          :|||,
          :||,
          :&,
          :when,
          :<-
        ]
    end
  end
end
