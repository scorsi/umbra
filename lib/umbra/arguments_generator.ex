defmodule Umbra.ArgumentsGenerator do
  @moduledoc false

  import Umbra.Helper

  defmodule InvalidArgumentsException do
    defexception message: "invalid arguments"
  end

  @doc """
  Generate arguments from an arguments list and depending of the given options.
  """
  @spec generate_arguments(arguments :: [tuple()], options :: keyword()) :: atom()
  def generate_arguments(arguments, options \\ []) when is_list(arguments) and is_list(options) do
    options = %{
      optimizations: Keyword.get(options, :optimizations, false),
      assignments: Keyword.get(options, :assignments, true),
      shadow: Keyword.get(options, :shadow, false),
      unshadow: Keyword.get(options, :unshadow, false),
      in_assignment?: false,
      index: 0
    }

    arguments
    |> Enum.with_index(1)
    |> Enum.map(fn {argument, index} ->
      do_generate_arguments(argument, %{options | index: index})
    end)
  end

  defp shadow(var) do
    var = Atom.to_string(var)

    if String.starts_with?(var, "_") do
      var
    else
      "_#{var}"
    end
    |> String.to_atom()
  end

  defp unshadow(var) do
    var = Atom.to_string(var)

    if String.starts_with?(var, "_") do
      var
      |> String.replace_prefix("_", "")
    else
      var
    end
    |> String.to_atom()
  end

  defp do_generate_arguments({:=, meta, [_, right]}, %{assignments: false} = options)
       when is_list(meta) do
    do_generate_arguments(right, options)
  end

  defp do_generate_arguments({:=, meta, [left, right]}, options) when is_list(meta) do
    {
      :=,
      meta,
      [
        do_generate_arguments(left, %{options | in_assignment?: true}),
        do_generate_arguments(right, options)
      ]
    }
  end

  defp do_generate_arguments(
         {op, meta, children},
         %{in_assignment?: false, assignments: false, optimizations: true, index: index}
       )
       when (is_supported_op(op) or op in [:{}, :%{}, :<<>>]) and is_list(meta) and
              is_list(children) do
    Macro.var(:"umbra_var_#{index}", nil)
  end

  defp do_generate_arguments(
         {op, meta, children},
         %{in_assignment?: false, assignments: true, optimizations: true, index: index} = options
       )
       when (is_supported_op(op) or op in [:{}, :%{}, :<<>>]) and is_list(meta) and
              is_list(children) do
    {
      :=,
      [],
      [
        {
          op,
          meta,
          Enum.map(
            children,
            &do_generate_arguments(&1, %{options | in_assignment?: true})
          )
        },
        Macro.var(:"umbra_var_#{index}", nil)
      ]
    }
  end

  defp do_generate_arguments(
         {op, meta, children},
         options
       )
       when (is_supported_op(op) or op in [:{}, :%{}, :<<>>]) and is_list(meta) and
              is_list(children) do
    {op, meta, Enum.map(children, &do_generate_arguments(&1, options))}
  end

  defp do_generate_arguments({op, meta, _}, _) when is_unsupported_op(op) and is_list(meta) do
    raise(RuntimeError, message: "unsupported operator, got: #{inspect(op)}")
  end

  defp do_generate_arguments({keyword, meta, _}, _)
       when is_registered_keyword(keyword) and is_list(meta) do
    raise(RuntimeError, message: "unsupported atom, got: #{inspect(keyword)}")
  end

  defp do_generate_arguments({var, meta, module}, %{shadow: true, in_assignment?: true})
       when is_atom(var) and is_list(meta) do
    {shadow(var), meta, module}
  end

  defp do_generate_arguments({var, meta, module}, %{unshadow: true, in_assignment?: false})
       when is_atom(var) and is_list(meta) do
    {unshadow(var), meta, module}
  end

  defp do_generate_arguments({var, meta, module}, _) when is_atom(var) and is_list(meta) do
    {var, meta, module}
  end

  defp do_generate_arguments({left, right}, options) do
    {do_generate_arguments(left, options), do_generate_arguments(right, options)}
  end

  defp do_generate_arguments(
         list,
         %{
           in_assignment?: false,
           assignments: false,
           optimizations: true,
           index: index
         }
       )
       when is_list(list) do
    Macro.var(:"umbra_var_#{index}", nil)
  end

  defp do_generate_arguments(
         list,
         %{in_assignment?: false, assignments: true, optimizations: true, index: index} = options
       )
       when is_list(list) do
    {
      :=,
      [],
      [
        Enum.map(list, &do_generate_arguments(&1, %{options | in_assignment?: true})),
        Macro.var(:"umbra_var_#{index}", nil)
      ]
    }
  end

  defp do_generate_arguments(list, options) when is_list(list) do
    Enum.map(list, &do_generate_arguments(&1, options))
  end

  defp do_generate_arguments(arg, _) when is_binary(arg) or is_number(arg) or is_atom(arg) do
    arg
  end

  defp do_generate_arguments(other, _) do
    raise(RuntimeError, message: "unsupported ast, got: #{inspect(other)}")
  end
end
