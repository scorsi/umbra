# Umbra [![Build Status](https://travis-ci.com/scorsi/umbra.svg?branch=master)](https://travis-ci.com/scorsi/umbra) [![Coverage Status](https://coveralls.io/repos/github/scorsi/umbra/badge.svg?branch=master)](https://coveralls.io/github/scorsi/umbra?branch=master)

Umbra is a GenServer utility helping you to easily create GenServer module.
It helps to reduce boilerplate code by offering you macros and code generation.

Nothing obscure or magic, the code is really readable and comprehensive.

## Installation

Add umbra for Elixir as a dependency in your mix.exs file.

```elixir
def deps do
  [
    {:umbra, "~> 0.0.1"},
  ]
end
```

After you are done, run this in your shell to fetch the new dependency:

```bash
$ mix deps.get
```

## Getting started

To get started, after adding the dependency to your mix project, you only have to use the [`Umbra.GenServer`](https://hexdocs.pm/umbra/Umbra.GenServer.html) and the codes did starts to be generated.

Here is a really simple exemple:

```elixir
defmodule BasicGenServer do
  use Umbra.GenServer

  definit do: {:ok, state}

  defcall {:get_state}, do: {:reply, state, state}

  defcast {:set_state, new_state}, do: {:noreply, new_state}

  defcast {:increment}, do: {:noreply, state + 1}

  defcast {:decrement}, do: {:noreply, state - 1}
end

{:ok, pid} = BasicGenServer.start_link(0) # state = 0
:ok = BasicGenServer.increment(pid) # state = 1
:ok = BasicGenServer.increment(pid) # state = 2
:ok = BasicGenServer.decrement(pid) # state = 1
:ok = BasicGenServer.set_state(pid, 42) # state = 42
{:ok, 42} = BasicGenServer.get_state(pid)
```

To deep further, please take a look at [HexDocs](https://hexdocs.pm/umbra).

## Tests

The project is tested for:

| Elixir version | OTP version |
| --- | --- |
| 1.7.4 | 19.4 |
| 1.7.4 | 20.3 |
| 1.7.4 | 21.3 |
| 1.7.4 | 22.3 |
| 1.8.2 | 20.3 |
| 1.8.2 | 21.3 |
| 1.8.2 | 22.3 |
| 1.9.4 | 20.3 |
| 1.9.4 | 21.3 |
| 1.9.4 | 22.3 |
| 1.10.3 | 21.3 |
| 1.10.3 | 22.3 |
| 1.10.3 | 23.0 |

## Contributing

Contributions are welcome!

- [Fork it](https://github.com/scorsi/umbra/fork)!
- Create your feature branch (`git checkout -b your-new-feature`).
- Commit your change in only one commit (`git commit -am "Add my new feature"`).
- Push your change on your fork (`git push origin your-new-feature`).
- Create a new [Pull Request](https://github.com/scorsi/umbra/compare).

## Author

Sylvain Corsini (@scorsi)

## Credits

The project took inspiration from the well-known [ExActor](https://github.com/sasa1977/exactor).

