defmodule Umbra.Operations do
  @moduledoc """
  Umbra.Operations
  """

  import Umbra.Helper

  defmacro defstart(definition, opts \\ []) do
    {fun, _} = extract_definition(definition)
    quote bind_quoted: [
            fun: fun,
            linked: Keyword.get(opts, :linked, true),
            default_state: Macro.escape(Keyword.get(opts, :default_state, nil), unquote: true)
          ] do
      def unquote(fun)(opts) do
        {state, opts} = Keyword.pop(opts, :state, unquote(default_state))
        __start__(unquote(linked), state, opts)
      end
    end
  end

  defmacro definit(opts \\ [], body \\ []) do
    opts = opts ++ body
    quote bind_quoted: [
            state: Macro.escape(Keyword.get(opts, :state, Macro.var(:state, nil)), unquote: true),
            body: Macro.escape(Keyword.get(opts, :do), unquote: true)
          ] do
      @impl GenServer
      def init(unquote(state)), do: unquote(body)
    end
  end

  defmacro defcall(definition, opts \\ [], body \\ []) do
    generate_functions(:call, definition, opts ++ body ++ [generate_client: true])
  end

  defmacro defcast(definition, opts \\ [], body \\ []) do
    generate_functions(:cast, definition, opts ++ body ++ [generate_client: true])
  end

  defmacro definfo(definition, opts \\ [], body \\ []) do
    generate_functions(:info, definition, opts ++ body ++ [generate_client: false])
  end

  defmacro defcontinue(definition, opts \\ [], body \\ []) do
    generate_functions(:continue, definition, opts ++ body ++ [generate_client: false])
  end

  defp generate_functions(type, definition, opts) do
    {fun, args} = extract_definition(definition)
    handler = generate_handler_tuple(fun, args)
    server_function = generate_server_function(type, handler, opts)
    client_function =
      if Keyword.get(opts, :generate_client) do
        generate_client_function(type, fun, args, handler, opts)
      else
        quote do end
      end

    quote do
      Module.eval_quoted(__MODULE__, unquote(client_function))
      Module.eval_quoted(__MODULE__, unquote(server_function))
    end
  end

  defp generate_client_function(type, fun, args, handler, _opts) do
    args = [Macro.var(:pid_or_state, __MODULE__)] ++ args

    quote do
      def unquote(fun)(unquote_splicing(args)) do
        case  __get_pid__(pid_or_state) do
          {:ok, pid} ->
            case GenServer.unquote(type)(pid, unquote(handler)) do
              :ok -> :ok
              result -> {:ok, result}
            end
          error -> error
        end
      end
    end
  end

  defp generate_server_function(type, handler, opts) do
    quote bind_quoted: [
            function_def:
              Macro.escape(
                generate_server_function_def(type, handler, Keyword.get(opts, :state, Macro.var(:state, nil))),
                unquote: true
              ),
            body: Macro.escape(Keyword.get(opts, :do), unquote: true)
          ] do
      @impl GenServer
      def unquote(function_def), do: unquote(body)
    end
  end

  defp generate_handler_tuple(fun, args) when args == [], do: quote do: {unquote(fun)}
  defp generate_handler_tuple(fun, args), do: quote do: {unquote(fun), unquote_splicing(args)}

  defp generate_server_function_def(:call, handler, state) do
    quote do
      handle_call(unquote(handler), from, unquote(state))
    end
  end
  defp generate_server_function_def(type, handler, state) do
    quote do
      unquote(:"handle_#{type}")(unquote(handler), unquote(state))
    end
  end
end
