defmodule ExSlop.Check.Refactor.SortThenAt do
  use Credo.Check,
    id: "EXS4021",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop, :credence],
    explanations: [
      check: """
      Sorting an entire list only to access one element is often unnecessary.

          # bad
          list |> Enum.sort() |> Enum.at(0)
          Enum.at(Enum.sort(list), 0)

          # good — for min/max cases
          Enum.min(list)
          Enum.max(list)
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

    if sort_then_at?(steps) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :at]}, _,
          [{{:., _, [{:__aliases__, _, [:Enum]}, :sort]}, _, [_ | _]}, _index]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp sort_then_at?(steps) do
    Enum.chunk_every(steps, 2, 1, :discard)
    |> Enum.any?(fn [left, right] ->
      ExSlop.Ast.remote_call?(left, :Enum, :sort) and ExSlop.Ast.remote_call?(right, :Enum, :at)
    end)
  end

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "Avoid `Enum.sort/1 |> Enum.at/2` when a single-pass selection such as `Enum.min/1` or `Enum.max/1` is enough.",
      trigger: "Enum.at",
      line_no: meta[:line]
    )
  end
end
