defmodule Umbra.DefinitionExtractor do
  @moduledoc """
  This module allows to retrieve function name and arguments from a definition.

  Definitions looks like this:

  ```elixir
  :func
  {:func}
  {:func, a}
  {:func, a, b}
  {:func, false}
  {:func, "_" <> rest = a}
  {:func, [head | tail] = a}
  {:func, %{id: id, name: name}}

  # Where :func is the name of your function.
  ```
  """

  @doc """
  Generate the `GenServer` parameter containing the message and the parameters.
  """
  @spec generate_handler_tuple(atom(), [tuple()]) :: tuple()
  def generate_handler_tuple(function_name, arguments)

  def generate_handler_tuple(fun, args) when args == [], do: quote do: {unquote(fun)}
  def generate_handler_tuple(fun, args), do: quote do: {unquote(fun), unquote_splicing(args)}

  @doc """
  Generate the server definition arguments.

  They still untouched from how the user defines it.
  """
  @spec generate_server_definition_args(atom(), tuple(), list()) :: [tuple()]
  def generate_server_definition_args(type, definition, options)

  def generate_server_definition_args(:init, nil, opts) do
    state = Keyword.get(opts, :state, Macro.var(:_state, nil))

    [state]
  end
  def generate_server_definition_args(:call, definition, opts) do
    from = Keyword.get(opts, :from, Macro.var(:_from, nil))
    state = Keyword.get(opts, :state, Macro.var(:_state, nil))

    handler = generate_handler_tuple(
      extract_function_name(definition),
      extract_arguments_for_declaration(definition)
    )

    [handler, from, state]
  end
  def generate_server_definition_args(_type, definition, opts) do
    state = Keyword.get(opts, :state, Macro.var(:_state, nil))

    handler = generate_handler_tuple(
      extract_function_name(definition),
      extract_arguments_for_declaration(definition)
    )

    [handler, state]
  end

  @doc """
  Generate the client call arguments but avoid extra/useless variable.
  """
  @spec generate_client_call_args(tuple()) :: tuple()
  def generate_client_call_args(definition)

  def generate_client_call_args(definition) do
    generate_handler_tuple(
      extract_function_name(definition),
      extract_arguments_for_call(definition)
    )
  end

  @doc """
  Generate the client definition arguments.

  They still quite untouched, only unused variable for the server call are automatically shadowed.
  """
  @spec generate_client_definition_args(tuple()) :: tuple()
  def generate_client_definition_args(definition)

  def generate_client_definition_args(definition) do
    [Macro.var(:pid_or_state, nil)] ++ (
      definition
      |> extract_arguments_for_declaration()
      |> Enum.map(&shadow_arguments/1))
  end

  @doc """
  This macro help know if the given atom is an operator.

  Example:

    iex> Umbra.DefinitionExtractor.is_op?(:%{})
    true

    iex> Umbra.DefinitionExtractor.is_op?(:%)
    true

    iex> Umbra.DefinitionExtractor.is_op?(:toto)
    false
  """
  defmacro is_op?(op) do
    quote do
      unquote(op) in [
        :_,
        :\\,
        :=,
        :%,
        :|,
        :"::",
        :%{},
        :{},
        :<<>>,
      ]
    end
  end

  @doc """
  This macro help know if the given atom is a Elixir registered keyword.

  Example:

    iex> Umbra.DefinitionExtractor.is_registered_keyword?(:def)
    true

    iex> Umbra.DefinitionExtractor.is_registered_keyword?(:toto)
    false
  """
  defmacro is_registered_keyword?(op) do
    quote do
      unquote(op) in [
        :def,
        :defp,
        :defmacro,
        :defmacrop,
        :defmodule,
      ]
    end
  end

  @doc """
  This macro help know if the given atom is a valid name for functions or variables.
  It should be used in when guards.

  Example:

    iex> Umbra.DefinitionExtractor.is_var_name?(:toto)
    true

    iex> Umbra.DefinitionExtractor.is_var_name?(:tata)
    true

    iex> Umbra.DefinitionExtractor.is_var_name?(:%{})
    false
  """
  defmacro is_var_name?(arg_name) do
    quote do
      is_atom(unquote(arg_name)) and not (unquote(arg_name) in [
        :_,
        :\\,
        :=,
        :%,
        :|,
        :"::",
        :%{},
        :{},
        :<<>>,
      ])
    end
  end

  @doc """
  Extract the function name from a function definition.

  Example:

      iex> Umbra.DefinitionExtractor.extract_function_name(quote do: :my_func)
      :my_func

      iex> Umbra.DefinitionExtractor.extract_function_name(quote do: {:toto, a})
      :toto

      iex> Umbra.DefinitionExtractor.extract_function_name(quote do: {:wow, a, b})
      :wow

      iex> Umbra.DefinitionExtractor.extract_function_name(quote do: {:my_func})
      :my_func

      iex> Umbra.DefinitionExtractor.extract_function_name(quote do: %{oops: true})
      ** (ArgumentError) invalid function definition
  """
  @spec extract_function_name(definition :: tuple() | atom()) :: atom()
  def extract_function_name(definition)

  def extract_function_name({:{}, _, [fun]}) when is_var_name?(fun),
      do: fun
  def extract_function_name({:{}, _, [fun | _]}) when is_var_name?(fun),
      do: fun
  def extract_function_name({fun, _}) when is_var_name?(fun),
      do: fun
  def extract_function_name(fun) when is_var_name?(fun),
      do: fun
  def extract_function_name(_),
      do: raise(ArgumentError, message: "invalid function definition")

  @doc """
  Extract the arguments used for function declaration from a function definition.

  Example:

      iex> Umbra.DefinitionExtractor.extract_arguments_for_declaration(quote do: {:func, a})
      [{:a, [], UmbraTest}]

      iex> Umbra.DefinitionExtractor.extract_arguments_for_declaration(quote do: {:func, a, b})
      [{:a, [], UmbraTest}, {:b, [], UmbraTest}]

      iex> Umbra.DefinitionExtractor.extract_arguments_for_declaration(quote do: {:func, %Test{} = a})
      [{:=, [], [{:%, [], [{:__aliases__, [alias: false], [:Test]}, {:%{}, [], []}]}, {:a, [], UmbraTest}]}]

      iex> Umbra.DefinitionExtractor.extract_arguments_for_declaration(quote do: {:func, 42})
      [42]

      iex> Umbra.DefinitionExtractor.extract_arguments_for_declaration(quote do: {:func, true, [name: "toto"]})
      [true, [name: "toto"]]
  """
  @spec extract_arguments_for_declaration(definition :: tuple() | atom()) :: [tuple()]
  def extract_arguments_for_declaration(definition)

  def extract_arguments_for_declaration({:{}, _, [_]}),
      do: []
  def extract_arguments_for_declaration({:{}, _, [_ | args]}),
      do: args
  def extract_arguments_for_declaration({_, arg}),
      do: [arg]
  def extract_arguments_for_declaration(_),
      do: []

  @doc """
  Extract the arguments used in calls from a function declaration.

  Example:

      iex> Umbra.DefinitionExtractor.extract_arguments_for_call(quote do: {:my_func})
      []

      iex> Umbra.DefinitionExtractor.extract_arguments_for_call(quote do: {:my_func, a})
      [{:a, [], UmbraTest}]

      iex> Umbra.DefinitionExtractor.extract_arguments_for_call(quote do: {:my_func, %{} = a, b})
      [{:a, [], UmbraTest}, {:b, [], UmbraTest}]

      iex> Umbra.DefinitionExtractor.extract_arguments_for_call(quote do: {:my_func, a, "toto" = b})
      [{:a, [], UmbraTest}, {:b, [], UmbraTest}]

      iex> Umbra.DefinitionExtractor.extract_arguments_for_call(quote do: {:my_func, true, []})
      [true, []]

      iex> Umbra.DefinitionExtractor.extract_arguments_for_call(quote do: {:my_func, [head | tail]})
      [[{:|, [], [{:head, [], UmbraTest}, {:tail, [], UmbraTest}]}]]

      iex> Umbra.DefinitionExtractor.extract_arguments_for_call(quote do: [:lol])
      ** (ArgumentError) invalid function definition
  """
  @spec extract_arguments_for_call(definition :: tuple() | atom()) :: [tuple()]
  def extract_arguments_for_call(definition)

  def extract_arguments_for_call({:{}, _, [_]}),
      do: []
  def extract_arguments_for_call({:{}, _, [_ | args]})
      when is_list(args),
      do: Enum.map(args, &extract_inner_arguments_for_call/1)
  def extract_arguments_for_call({_, arg}),
      do: [extract_inner_arguments_for_call(arg)]
  def extract_arguments_for_call(_),
      do: raise(ArgumentError, message: "invalid function definition")

  @doc """
  Extract the argument used in call from an argument declaration.

  Example:

      iex> Umbra.DefinitionExtractor.extract_inner_arguments_for_call(quote do: a)
      {:a, [], UmbraTest}

      iex> Umbra.DefinitionExtractor.extract_inner_arguments_for_call(quote do: [] = my_array)
      {:my_array, [], UmbraTest}

      iex> Umbra.DefinitionExtractor.extract_inner_arguments_for_call(quote do: %{} = my_struct)
      {:my_struct, [], UmbraTest}

      iex> Umbra.DefinitionExtractor.extract_inner_arguments_for_call(quote do: 32 = my_number)
      {:my_number, [], UmbraTest}

      iex> Umbra.DefinitionExtractor.extract_inner_arguments_for_call(quote do: :test = my_atom)
      {:my_atom, [], UmbraTest}

      iex> Umbra.DefinitionExtractor.extract_inner_arguments_for_call(quote do: "test" = my_string)
      {:my_string, [], UmbraTest}

      iex> Umbra.DefinitionExtractor.extract_inner_arguments_for_call(quote do: nil)
      nil

      iex> Umbra.DefinitionExtractor.extract_inner_arguments_for_call(quote do: 42)
      42

      iex> Umbra.DefinitionExtractor.extract_inner_arguments_for_call(quote do: [])
      []

      iex> Umbra.DefinitionExtractor.extract_inner_arguments_for_call(quote do: [head | tail])
      [{:|, [], [{:head, [], UmbraTest}, {:tail, [], UmbraTest}]}]

      iex> Umbra.DefinitionExtractor.extract_inner_arguments_for_call(quote do: [name: "toto"])
      [name: "toto"]

      iex> Umbra.DefinitionExtractor.extract_inner_arguments_for_call(quote do: %{})
      {:%{}, [], []}

      iex> Umbra.DefinitionExtractor.extract_inner_arguments_for_call(quote do: %{name: "toto"})
      {:%{}, [], [name: "toto"]}

      iex> Umbra.DefinitionExtractor.extract_inner_arguments_for_call(quote do: %{"name" => "toto"})
      {:%{}, [], [{"name", "toto"}]}

      iex> Umbra.DefinitionExtractor.extract_inner_arguments_for_call(quote do: :test)
      :test

      iex> Umbra.DefinitionExtractor.extract_inner_arguments_for_call(quote do: "test")
      "test"

      iex> Umbra.DefinitionExtractor.extract_inner_arguments_for_call(quote do: %Test{})
      {:%, [], [{:__aliases__, [alias: false], [:Test]}, {:%{}, [], []}]}

      iex> Umbra.DefinitionExtractor.extract_inner_arguments_for_call(quote do: toto())
      ** (ArgumentError) invalid argument declaration

      iex> Umbra.DefinitionExtractor.extract_inner_arguments_for_call(quote do: (defmodule TOTO do end))
      ** (ArgumentError) invalid argument declaration
  """
  @spec extract_inner_arguments_for_call(definition :: tuple() | atom()) :: [tuple()]
  def extract_inner_arguments_for_call(definition)

  def extract_inner_arguments_for_call({:=, _, [_, {arg_name, _, _} = arg]})
      when is_var_name?(arg_name),
      do: arg
  def extract_inner_arguments_for_call({op, _ = context, args})
      when op in [:%{}, :{}, :%],
      do: {op, context, args}
  def extract_inner_arguments_for_call({op, _ = context, args})
      when is_op?(op) and is_list(args),
      do: {op, context, Enum.map(args, &extract_inner_arguments_for_call/1)}
  def extract_inner_arguments_for_call({a, _, _})
      when is_registered_keyword?(a),
      do: raise(ArgumentError, message: "invalid argument declaration")
  def extract_inner_arguments_for_call({fun, _, []})
      when is_var_name?(fun),
      do: raise(ArgumentError, message: "invalid argument declaration")
  def extract_inner_arguments_for_call({arg_name, _, _} = arg)
      when is_var_name?(arg_name),
      do: arg
  def extract_inner_arguments_for_call(arg)
      when is_binary(arg),
      do: arg
  def extract_inner_arguments_for_call(arg)
      when is_number(arg),
      do: arg
  def extract_inner_arguments_for_call(arg)
      when is_atom(arg),
      do: arg
  def extract_inner_arguments_for_call(arg)
      when is_list(arg),
      do: arg
  def extract_inner_arguments_for_call(nil),
      do: nil
  def extract_inner_arguments_for_call(_),
      do: raise(ArgumentError, message: "invalid argument declaration")

  @doc """
  Shadow inner argument declaration used for client function declaration.

  Example:

      iex> Umbra.DefinitionExtractor.shadow_arguments(quote do: 42 = a)
      {:=, [], [42, {:a, [], UmbraTest}]}

      iex> Umbra.DefinitionExtractor.shadow_arguments(quote do: %{test: test} = a)
      {:=, [], [{:%{}, [], [test: {:_test, [], UmbraTest}]}, {:a, [], UmbraTest}]}

      iex> Umbra.DefinitionExtractor.shadow_arguments(quote do: [head | tail] = a)
      {:=, [], [[{:|, '', [{:_head, [], UmbraTest}, {:_tail, '', UmbraTest}]}], {:a, '', UmbraTest}]}

      iex> Umbra.DefinitionExtractor.shadow_arguments(quote do: [head | tail])
      [{:|, [], [{:head, [], UmbraTest}, {:tail, '', UmbraTest}]}]

      iex> Umbra.DefinitionExtractor.shadow_arguments(quote do: [head | tail])
      [{:|, [], [{:head, [], UmbraTest}, {:tail, [], UmbraTest}]}]
  """
  @spec shadow_arguments(definition :: tuple() | atom()) :: [tuple()]
  def shadow_arguments(definition)

  def shadow_arguments({:=, _ = context, [values, _ = var]}),
      do: {:=, context, [shadow_inner_arguments(values), var]}
  def shadow_arguments(arg),
      do: arg

  @doc """
  Shadow left value in argument declaration/assignment used for client function declaration.

  Example:

      iex> Umbra.DefinitionExtractor.shadow_inner_arguments(quote do: 42)
      42

      iex> Umbra.DefinitionExtractor.shadow_inner_arguments(quote do: %{test: test})
      {:%{}, [], [test: {:_test, [], UmbraTest}]}

      iex> Umbra.DefinitionExtractor.shadow_inner_arguments(quote do: [])
      []

      iex> Umbra.DefinitionExtractor.shadow_inner_arguments(quote do: [head | tail])
      [{:|, '', [{:_head, [], UmbraTest}, {:_tail, '', UmbraTest}]}]

      iex> Umbra.DefinitionExtractor.shadow_inner_arguments(quote do: %Test{id: 42})
      {:%, [], [{:__aliases__, [alias: false], [:Test]}, {:%{}, [], [id: 42]}]}

      iex> Umbra.DefinitionExtractor.shadow_inner_arguments(quote do: %Test{id: id})
      {:%, [], [{:__aliases__, [alias: false], [:Test]}, {:%{}, [], [id: {:_id, [], UmbraTest}]}]}

      iex> Umbra.DefinitionExtractor.shadow_inner_arguments(quote do: [true = tata, false = toto])
      [{:=, [], [true, {:_tata, [], UmbraTest}]}, {:=, [], [false, {:_toto, [], UmbraTest}]}]

      iex> Umbra.DefinitionExtractor.shadow_inner_arguments(quote do: [[true = tata, false = toto] | others])
      [{:|, [], [[{:=, [], [true, {:_tata, [], UmbraTest}]}, {:=, [], [false, {:_toto, [], UmbraTest}]}], {:_others, [], UmbraTest}]}]

      iex> Umbra.DefinitionExtractor.shadow_inner_arguments(quote do: <<32 :: a>>)
      {:<<>>, [], [{:"::", [], [32, {:_a, [], UmbraTest}]}]}

      iex> Umbra.DefinitionExtractor.shadow_inner_arguments(quote do: %{id: _id, name: _name})
      {:%{}, '', [{:id, {:_id, [], UmbraTest}}, {:name, {:_name, [], UmbraTest}}]}
  """
  @spec shadow_inner_arguments(definition :: tuple() | atom()) :: [tuple()]
  def shadow_inner_arguments(definition)

  def shadow_inner_arguments({op, _ = context, values})
      when is_op?(op),
      do: {op, context, Enum.map(values, &shadow_inner_arguments/1)}
  def shadow_inner_arguments(list)
      when is_list(list),
      do: Enum.map(list, &shadow_inner_arguments/1)
  def shadow_inner_arguments({arg_name, _ = context, _ = module} = inner_argument)
      when is_var_name?(arg_name),
      do: (
        if arg_name
           |> Atom.to_string()
           |> String.starts_with?("_") do
          inner_argument
        else
          {:"_#{arg_name}", context, module}
        end)
  def shadow_inner_arguments({val, inner_arg})
      when is_var_name?(val) and is_tuple(inner_arg),
      do: {val, shadow_inner_arguments(inner_arg)}
  def shadow_inner_arguments(v),
      do: v
end
