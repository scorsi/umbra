defmodule Umbra.FunctionGenerator do
  @moduledoc """
  This module generate code.

  It is used for client-side and server-side function generation.
  """

  alias Umbra.ArgumentsGenerator
  alias Umbra.DefinitionExtractor

  def add_to_module(functions) when is_list(functions) do
    quote do
      for function <- unquote(functions) do
        Module.eval_quoted(__MODULE__, function)
      end
    end
  end

  def add_to_module(function) do
    quote do
      Module.eval_quoted(__MODULE__, unquote(function))
    end
  end

  def generate_function(function_name, arguments, body, opts) do
    private = Keyword.get(opts, :private, false)
    decorator = Keyword.get(opts, :decorator, nil)
    guards = Keyword.get(opts, :guards, nil)

    quote unquote: true,
          bind_quoted: [
            function_name: function_name,
            arguments: Macro.escape(arguments, unquote: true),
            body: Macro.escape(body, unquote: true)
          ] do
      def unquote(function_name)(unquote_splicing(arguments)) do
        unquote(body)
      end
    end
    |> change_private_in_function_ast(function_name, private)
    |> add_decorator_in_function_ast(function_name, decorator)
    |> add_when_in_function_ast(function_name, guards)
  end

  def generate_client_function(type, definition, opts) when type in [:call, :cast, :info] do
    private = Keyword.get(opts, :private, false)
    guards = Keyword.get(opts, :when)

    generate_function(
      DefinitionExtractor.extract_function_name_from_definition(definition),
      generate_client_definition_args(definition),
      generate_client_inner_function(type, generate_client_handler(definition)),
      private: private,
      guards: guards
    )
  end

  def generate_server_function(type, definition, opts)
      when type in [:init, :call, :cast, :info, :continue] do
    body = Keyword.get(opts, :do)
    guards = Keyword.get(opts, :when)

    generate_function(
      case type do
        :init -> :init
        _ -> :"handle_#{type}"
      end,
      generate_server_definition_args(type, definition, opts),
      generate_server_inner_function(type, body),
      decorator: GenServer,
      guards: guards
    )
  end

  defp generate_client_definition_args(definition) do
    [Macro.var(:pid_or_state, nil)] ++
      (definition
       |> DefinitionExtractor.extract_arguments_from_definition()
       |> ArgumentsGenerator.generate_arguments(
         unshadow: true,
         shadow: true,
         optimizations: true
       ))
  end

  defp generate_server_definition_args(:init, nil, opts) do
    [
      Keyword.get(opts, :state, Macro.var(:_state, nil))
    ]
  end

  defp generate_server_definition_args(:call, definition, opts) do
    [
      generate_server_handler(definition),
      Keyword.get(opts, :from, Macro.var(:_from, nil)),
      Keyword.get(opts, :state, Macro.var(:_state, nil))
    ]
  end

  defp generate_server_definition_args(_type, definition, opts) do
    [
      generate_server_handler(definition),
      Keyword.get(opts, :state, Macro.var(:_state, nil))
    ]
  end

  defp generate_client_handler(definition) do
    generate_handler(
      DefinitionExtractor.extract_function_name_from_definition(definition),
      definition
      |> DefinitionExtractor.extract_arguments_from_definition()
      |> ArgumentsGenerator.generate_arguments(
        unshadow: true,
        assignments: false,
        optimizations: true
      )
    )
  end

  defp generate_server_handler(definition) do
    generate_handler(
      DefinitionExtractor.extract_function_name_from_definition(definition),
      DefinitionExtractor.extract_arguments_from_definition(definition)
    )
  end

  defp generate_handler(fun, args) when args == [], do: quote(do: unquote(fun))
  defp generate_handler(fun, args), do: quote(do: {unquote(fun), unquote_splicing(args)})

  defp generate_client_inner_function(:info, argument) do
    quote do
      case __get_pid__(unquote(Macro.var(:pid_or_state, nil))) do
        {:ok, pid} ->
          case Process.send(pid, unquote(argument), []) do
            :ok -> :ok
            error -> {:error, error}
          end

        error ->
          error
      end
    end
  end

  defp generate_client_inner_function(type, argument) do
    quote do
      case __get_pid__(unquote(Macro.var(:pid_or_state, nil))) do
        {:ok, pid} ->
          case GenServer.unquote(type)(pid, unquote(argument)) do
            :ok -> :ok
            result -> {:ok, result}
          end

        error ->
          error
      end
    end
  end

  defp generate_server_inner_function(:init, body) do
    quote do
      case __init__(unquote(Macro.var(:state, nil))) do
        {:ok, state} ->
          unquote(body)

        e ->
          e
      end
    end
  end

  defp generate_server_inner_function(_type, body) do
    quote do
      unquote(body)
    end
  end

  defp change_private_in_function_ast(function, _function_name, false), do: function

  defp change_private_in_function_ast(function, function_name, true) do
    function
    |> Macro.postwalk(fn
      {:def, _ = context, [{^function_name, _, _}, _] = args} ->
        {:defp, context, args}

      other ->
        other
    end)
  end

  defp add_decorator_in_function_ast(function, _function_name, nil), do: function

  defp add_decorator_in_function_ast(function, function_name, decorator) do
    function
    |> Macro.postwalk(fn
      {_, _, [{^function_name, _, _}, _]} = func ->
        {
          :__block__,
          [],
          [
            quote(do: @impl(unquote(decorator))),
            func
          ]
        }

      other ->
        other
    end)
  end

  defp add_when_in_function_ast(function, _function_name, nil), do: function

  defp add_when_in_function_ast(function, function_name, guards) do
    function
    |> Macro.postwalk(fn
      {_ = def, _ = context, [{^function_name, _, _} = func_def, body]} ->
        {def, context, [{:when, context, [func_def, guards]}, body]}

      other ->
        other
    end)
  end
end
