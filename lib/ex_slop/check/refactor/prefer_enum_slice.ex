defmodule ExSlop.Check.Refactor.PreferEnumSlice do
  use Credo.Check,
    id: "EXS4018",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop, :credence],
    explanations: [
      check: """
      `Enum.drop/2 |> Enum.take/2` is more clearly expressed as `Enum.slice/3`.

          # bad
          items |> Enum.drop(offset) |> Enum.take(limit)

          # good
          Enum.slice(items, offset, limit)

      Negative literal arguments are not reported: `Enum.drop/2` and
      `Enum.take/2` count from the end for negative values, while
      `Enum.slice/3` interprets a negative start differently and rejects a
      negative amount.

          # not flagged — drops the last two, then takes the first
          items |> Enum.drop(-2) |> Enum.take(1)
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:|>, meta, _} = ast, ctx) do
    steps = ExSlop.Ast.pipeline_steps(ast)

    if drop_take_pipeline?(steps) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp drop_take_pipeline?(steps) do
    Enum.chunk_every(steps, 2, 1, :discard)
    |> Enum.any?(fn [left, right] ->
      ExSlop.Ast.remote_call?(left, :Enum, :drop) and
        ExSlop.Ast.remote_call?(right, :Enum, :take) and
        not negative_literal_arg?(left) and not negative_literal_arg?(right)
    end)
  end

  defp negative_literal_arg?({_, _, [arg]}), do: negative_literal?(arg)
  defp negative_literal_arg?(_), do: false

  defp negative_literal?(int) when is_integer(int), do: int < 0
  defp negative_literal?({:-, _, [int]}) when is_integer(int), do: true
  defp negative_literal?(_), do: false

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message: "Use `Enum.slice/3` instead of `Enum.drop/2 |> Enum.take/2`.",
      trigger: "Enum.take",
      line_no: meta[:line]
    )
  end
end
