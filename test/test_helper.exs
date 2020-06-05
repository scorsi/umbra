ExUnit.start()

defmodule Generator do
  use Quixir

  @max_arg 8
  @max_elem 10
  @max_deep 3

  defp generate_map(deep) do
    tuple(
      like:
        {value(:%{}), value([]),
         list(of: tuple(like: {string(), choose(from: generate_any(deep))}), max: @max_elem)}
    )
  end

  defp generate_tuple(deep) do
    choose(
      from: [
        tuple(
          like:
            {value(:{}), value([]),
             list(of: choose(from: generate_any(deep)), min: 3, max: @max_elem)}
        ),
        tuple(
          like:
            {value(:{}), value([]), list(of: choose(from: generate_any(deep)), min: 1, max: 1)}
        ),
        tuple(like: {choose(from: generate_any(deep)), choose(from: generate_any(deep))})
      ]
    )
  end

  defp generate_list(deep) do
    list(of: choose(from: generate_any(deep)), max: @max_elem)
  end

  defp generate_var() do
    tuple(like: {atom(min: 4), value([]), value(__MODULE__)})
  end

  defp generate_assignment(deep) do
    tuple(
      like:
        {value(:=), value([]),
         list(of: seq(of: [choose(from: generate_any(deep)), generate_var()]), min: 2, max: 2)}
    )
  end

  defp generate_any(0) do
    generate_any(1) ++ [generate_assignment(1)]
  end

  defp generate_any(deep) do
    [
      int(),
      float(),
      atom(min: 4),
      bool(),
      string(chars: :utf),
      generate_var()
    ] ++
      if deep <= @max_deep do
        [
          generate_list(deep + 1),
          generate_map(deep + 1),
          generate_tuple(deep + 1)
        ]
      else
        []
      end
  end

  def generate_random_arguments() do
    list(
      of: choose(from: generate_any(0)),
      max: @max_arg
    )
  end

  def generate_random_definition do
    choose(
      from: [
        atom(),
        tuple(like: {atom(min: 4), choose(from: generate_any(0))}),
        tuple(like: {value(:{}), value([]), list(of: atom(min: 4), min: 1, max: 1)}),
        tuple(
          like: {
            value(:{}),
            value([]),
            list(
              of:
                seq(
                  of: [
                    atom(min: 4),
                    choose(from: generate_any(0)),
                    choose(from: generate_any(0))
                  ]
                ),
              min: 3,
              max: 3
            )
          }
        ),
        tuple(
          like: {
            value(:{}),
            value([]),
            list(
              of:
                seq(
                  of: [
                    atom(min: 4),
                    choose(from: generate_any(0)),
                    choose(from: generate_any(0)),
                    choose(from: generate_any(0))
                  ]
                ),
              min: 4,
              max: 4
            )
          }
        ),
        tuple(
          like: {
            value(:{}),
            value([]),
            list(
              of:
                seq(
                  of: [
                    atom(min: 4),
                    choose(from: generate_any(0)),
                    choose(from: generate_any(0)),
                    choose(from: generate_any(0)),
                    choose(from: generate_any(0))
                  ]
                ),
              min: 5,
              max: 5
            )
          }
        )
      ]
    )
  end
end
