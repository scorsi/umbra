# Umbra [![Build Status](https://travis-ci.com/scorsi/umbra.svg?branch=master)](https://travis-ci.com/scorsi/umbra) [![Coverage Status](https://coveralls.io/repos/github/scorsi/umbra/badge.svg?branch=master)](https://coveralls.io/github/scorsi/umbra?branch=master) [![Hex.pm](https://img.shields.io/hexpm/v/umbra.svg)](https://hex.pm/packages/umbra) [![Hex.pm](https://img.shields.io/hexpm/dt/umbra.svg)](https://hex.pm/packages/umbra)


Umbra helps you make your GenServer rocks in lesser code, inspired by ExActor.

We all know [ExActor](https://github.com/sasa1977/exactor) which is a good project... which was... here the issues of ExActor:
- is not maintained since 2017,
- didn't support last GenServer functionalities like `continue`,
- did generate a lot of warnings in the user codebase like unused variables,
- isn't extensible.

Umbra has been inspired by ExActor, but nothing more, it is a totally re-write.
 Umbra has a lightweight, well tested, highly documented and very comprehensive codebase.

The main differences with ExActor are :
- you have to declare function like you would normally do in the `handle_*` functions or `GenServer.*` call.
 For example: `{:set_state, new_state}` and not like `set_state(new_state)`.

Umbra understands what you write :
 - in the function definition,
 - in the when guard,
 - or in the state alias.

It will automatically :
 - shadow unused variables,
 - un-shadow necessary variables,
 - create variables to optimize code,
 - reduce code complexity when needed 
 - and all of this without your attention.

Actually Umbra lacks some features like `multicall` and `abcast` in addition to the `defstart`
 which is internally done and not configurable to the user.

If you feel that Umbra lacks something or if you dive into a bug,
 don't hesitate to create an issue or create a PR.

## Installation

Add umbra for Elixir as a dependency in your mix.exs file.

```elixir
def deps do
  [
    {:umbra, "~> 0.1.0"},
  ]
end
```

After you are done, fetch the new dependency:

```bash
$ mix deps.get
```

## Getting started

To get started, after adding the dependency to your mix project, you only have
 to use the [`Umbra.GenServer`](https://hexdocs.pm/umbra/Umbra.GenServer.html) 
 and your GenServer already did start to being generated.

Here is a really simple exemple:

```elixir
defmodule BasicGenServer do
  use Umbra.GenServer

  definit state: state, do: {:ok, state}

  defcall {:get_state}, state: state, do: {:reply, state, state}

  defcast {:set_state, new_state}, do: {:noreply, new_state}

  defcast {:increment}, state: state, do: {:noreply, state + 1}

  defcast {:decrement}, state: state, do: {:noreply, state - 1}
end

{:ok, pid} = BasicGenServer.start_link(0) # state = 0
:ok = BasicGenServer.increment(pid) # state = 1
:ok = BasicGenServer.increment(pid) # state = 2
:ok = BasicGenServer.decrement(pid) # state = 1
:ok = BasicGenServer.set_state(pid, 42) # state = 42
{:ok, 42} = BasicGenServer.get_state(pid)
```

To deep further, please take a look at [HexDocs](https://hexdocs.pm/umbra).

## What do Umbra under the hood

Here is a notable example:
```elixir
defcall {:do_computation, {a, b}, _c}, when: is_number(a), state: state do
  {:reply, a + b, state}
end

# The generated code
def do_computation(pid, {a, _b} = umbra_arg_1, c) when is_number(a) do
  GenServer.call(pid, {:do_computation, umbra_arg_1, c})
end
def handle_call({:do_computation, {a, b}, _c}, _from, state) when is_number(a) do
  {:reply, a + b, state}
end
```
Here what you can notice in this example:
- Umbra add a new variable `umbra_arg_1` to optimize the code. Passing `{a, b}` to the GenServer call
 could be simpler but not optimized.
- Umbra automatically shadow the `b` variable to avoid warning for unused variable.
 But it didn't do the same for the `a` variable since it is used in the when clause.
- Umbra did automatically un-shadow the `c` variable in the client-side function to avoid warning because
 it is used in the GenServer call. 

_Note: actually un-shadow and variable optimizations are not yet implemented but will come in the next updates._

## Tests

The project is tested for:

| Elixir version | OTP version |
| --- | --- |
| 1.7.4 | 21.3 |
| 1.7.4 | 22.3 |
| 1.8.2 | 21.3 |
| 1.8.2 | 22.3 |
| 1.9.4 | 21.3 |
| 1.9.4 | 22.3 |
| 1.10.3 | 21.3 |
| 1.10.3 | 22.3 |
| 1.10.3 | 23.0 |

Compatibility-issues only in tests for `otp < 21` caused primarily by the missing GenServer `continue` feature.

## Contributing

Contributions are welcome!

- [Fork it](https://github.com/scorsi/umbra/fork)!
- Create your feature branch (`git checkout -b your-new-feature`).
- Commit your change in only one commit (`git commit -am "Add my new feature"`).
- Push your change on your fork (`git push origin your-new-feature`).
- Create a new [Pull Request](https://github.com/scorsi/umbra/compare).

## Author

Sylvain Corsini ([@scorsi](https://github.com/scorsi))

## Credits

This project took inspiration from the well-known [ExActor](https://github.com/sasa1977/exactor).
