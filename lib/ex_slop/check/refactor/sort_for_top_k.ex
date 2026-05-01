defmodule ExSlop.Check.Refactor.SortForTopK do
  use Credo.Check,
    id: "EXS4022",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop, :credence],
    explanations: [
      check: """
      Sorting the whole collection just to take a single element does extra work.

          # bad
          list |> Enum.sort() |> Enum.take(1)
          list |> Enum.sort() |> hd()

          # good — when only one value is needed
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

    if sort_for_top_k?(steps) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp sort_for_top_k?(steps) do
    steps
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.any?(fn [left, right] ->
      ExSlop.Ast.remote_call?(left, :Enum, :sort) and top_k_call?(right)
    end)
  end

  defp top_k_call?({{:., _, [{:__aliases__, _, [:Enum]}, :take]}, _, [1]}), do: true

  defp top_k_call?({:hd, _, []}), do: true
  defp top_k_call?(_), do: false

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "Avoid fully sorting a collection just to take one result; use min/max or a single-pass selection when possible.",
      trigger: "Enum.sort",
      line_no: meta[:line]
    )
  end
end
