defmodule Umbra.CodeGenerator do
  @moduledoc """
  This module generate code.

  It is used for client-side and server-side function generation.
  """

  alias Umbra.DefinitionExtractor

  def add_to_module(functions) when is_list(functions) do
    quote do
      for function <- unquote(functions) do
        Module.eval_quoted(__MODULE__, function)
      end
    end
  end
  def add_to_module(function)  do
    quote do
      Module.eval_quoted(__MODULE__, unquote(function))
    end
  end

  def generate_function(function_name, arguments, body, decorator, private, guards) do
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


  defp change_private_in_function_ast(function, _function_name, false), do: function
  defp change_private_in_function_ast(function, function_name, true) do
    function
    |> Macro.postwalk(
         fn
           {:def, _ = context, [{^function_name, _, _}, _] = args} ->
             {:defp, context, args}

           other -> other
         end
       )
  end

  defp add_decorator_in_function_ast(function, _function_name, nil), do: function
  defp add_decorator_in_function_ast(function, function_name, decorator) do
    function
    |> Macro.postwalk(
         fn
           {_, _, [{^function_name, _, _}, _]} = func ->
             {
               :__block__,
               [],
               [
                 (quote do: @impl unquote(decorator)),
                 func
               ]
             }

           other -> other
         end
       )
  end

  defp add_when_in_function_ast(function, _function_name, nil), do: function
  defp add_when_in_function_ast(function, function_name, guards) do
    function
    |> Macro.postwalk(
         fn
           {_ = def, _ = context, [{^function_name, _, _} = func_def, body]} ->
             {def, context, [{:when, context, [func_def, guards]}, body]}

           {_, _, [{:when, _, [{^function_name, _, _}, _]}, _]} ->
             raise(RuntimeError, message: "a when clause is already declared")

           other -> other
         end
       )
  end

  def generate_client_function(type, definition, opts) when type in [:call, :cast, :info] do
    private = Keyword.get(opts, :private, false)
    guards = Keyword.get(opts, :when)

    function_name = DefinitionExtractor.extract_function_name(definition)
    client_definition_args = DefinitionExtractor.generate_client_definition_args(definition)
    client_call_args = DefinitionExtractor.generate_client_call_args(definition)

    generate_function(
      function_name,
      client_definition_args,
      generate_client_inner_function(type, client_call_args),
      nil,
      private,
      guards
    )
  end
  def generate_client_function(type, _, _),
      do: raise(ArgumentError, message: "invalid type for client function, got: #{type}")

  defp generate_client_inner_function(:info, argument) do
    quote do
      case  __get_pid__(unquote(Macro.var(:pid_or_state, nil))) do
        {:ok, pid} ->
          case Process.send(
                 unquote(Macro.var(:pid_or_state, nil)),
                 unquote(argument)
               ) do
            :ok -> :ok
            error -> {:error, error}
          end
        error -> error
      end
    end
  end
  defp generate_client_inner_function(type, argument) do
    quote do
      case  __get_pid__(unquote(Macro.var(:pid_or_state, nil))) do
        {:ok, pid} ->
          case GenServer.unquote(type)(
                 unquote(Macro.var(:pid_or_state, nil)),
                 unquote(argument)
               ) do
            :ok -> :ok
            result -> {:ok, result}
          end
        error -> error
      end
    end
  end

  def generate_server_function(type, definition, opts) when type in [:init, :call, :cast, :info, :continue] do
    body = Keyword.get(opts, :do)
    guards = Keyword.get(opts, :when)

    server_definition_args = DefinitionExtractor.generate_server_definition_args(type, definition, opts)

    generate_function(
      case type do
        :init -> :init
        _ -> :"handle_#{type}"
      end,
      server_definition_args,
      generate_server_inner_function(type, body),
      GenServer,
      false,
      guards
    )
  end
  def generate_server_function(type, _, _),
      do: raise(ArgumentError, message: "invalid type for server function, got: #{type}")

  defp generate_server_inner_function(:init, body) do
    quote do
      case __init__(unquote(Macro.var(:state, nil))) do
        {:ok, state} ->
          unquote(body)
        e -> e
      end
    end
  end
  defp generate_server_inner_function(_type, body) do
    quote do
      unquote(body)
    end
  end
end
