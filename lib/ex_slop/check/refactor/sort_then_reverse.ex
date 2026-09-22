defmodule ExSlop.Check.Refactor.SortThenReverse do
  use Credo.Check,
    id: "EXS4009",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      `Enum.sort/1 |> Enum.reverse/1` should be `Enum.sort(:desc)`.

          # bad
          list |> Enum.sort() |> Enum.reverse()
          Enum.reverse(Enum.sort(list))

          # good
          Enum.sort(list, :desc)

      `Enum.sort_by/2 |> Enum.reverse/1` is deliberately not reported.
      Sorting is stable, so reversing an ascending sort also reverses the
      relative order of elements with equal keys, while
      `Enum.sort_by(fun, :desc)` keeps them in their original order:

          [a: 1, b: 1] |> Enum.sort_by(&elem(&1, 1)) |> Enum.reverse()
          # => [b: 1, a: 1]

          Enum.sort_by([a: 1, b: 1], &elem(&1, 1), :desc)
          # => [a: 1, b: 1]
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # Enum.sort(list) |> Enum.reverse()
  defp walk(
         {:|>, _,
          [
            {{:., _, [{:__aliases__, _, [:Enum]}, :sort]}, _, [_enumerable]},
            {{:., meta, [{:__aliases__, _, [:Enum]}, :reverse]}, _, []}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  # ... |> Enum.sort() |> Enum.reverse()
  defp walk(
         {:|>, _,
          [
            {:|>, _,
             [
               _,
               {{:., _, [{:__aliases__, _, [:Enum]}, :sort]}, _, []}
             ]},
            {{:., meta, [{:__aliases__, _, [:Enum]}, :reverse]}, _, []}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  # Enum.reverse(Enum.sort(list))
  defp walk(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :reverse]}, _,
          [
            {{:., _, [{:__aliases__, _, [:Enum]}, :sort]}, _, [_enumerable]}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message: "`Enum.sort/1 |> Enum.reverse/1` — use `Enum.sort(:desc)` instead.",
      trigger: "reverse",
      line_no: meta[:line]
    )
  end
end
