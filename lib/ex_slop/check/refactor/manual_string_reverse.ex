defmodule ExSlop.Check.Refactor.ManualStringReverse do
  use Credo.Check,
    id: "EXS4020",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop, :credence],
    explanations: [
      check: """
      `String.graphemes/1 |> Enum.reverse/1 |> Enum.join/1` manually reimplements `String.reverse/1`.

          # bad
          string |> String.graphemes() |> Enum.reverse() |> Enum.join()

          # good
          String.reverse(string)
      """
    ]

  alias ExSlop.Ast

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:|>, meta, _} = ast, ctx) do
    steps = ExSlop.Ast.pipeline_steps(ast)

    if manual_reverse_pipeline?(steps) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp manual_reverse_pipeline?(steps) do
    Enum.chunk_every(steps, 3, 1, :discard)
    |> Enum.any?(fn [first, second, third] ->
      Ast.remote_call?(first, :String, :graphemes) and
        Ast.remote_call?(second, :Enum, :reverse) and
        Ast.remote_call?(third, :Enum, :join)
    end)
  end

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "Use `String.reverse/1` instead of `String.graphemes/1 |> Enum.reverse/1 |> Enum.join/1`.",
      trigger: "String.graphemes",
      line_no: meta[:line]
    )
  end
end
