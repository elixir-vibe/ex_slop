defmodule ExSlop.Check.Refactor.UseMapJoin do
  use Credo.Check,
    id: "EXS4017",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop, :credence],
    explanations: [
      check: """
      `Enum.map/2 |> Enum.join/1` creates an intermediate list.

          # bad
          items |> Enum.map(&to_string/1) |> Enum.join(",")

          # good
          Enum.map_join(items, ",", &to_string/1)
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

    if map_join_pipeline?(steps) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp map_join_pipeline?(steps) do
    Enum.chunk_every(steps, 2, 1, :discard)
    |> Enum.any?(fn [left, right] ->
      ExSlop.Ast.remote_call?(left, :Enum, :map) and ExSlop.Ast.remote_call?(right, :Enum, :join)
    end)
  end

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "Use `Enum.map_join/3` instead of `Enum.map/2 |> Enum.join/1` to avoid an intermediate list.",
      trigger: "Enum.join",
      line_no: meta[:line]
    )
  end
end
