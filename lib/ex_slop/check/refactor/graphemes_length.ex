defmodule ExSlop.Check.Refactor.GraphemesLength do
  use Credo.Check,
    id: "EXS4019",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop, :credence],
    explanations: [
      check: """
      `String.graphemes/1 |> length/1` builds an intermediate list just to count it.

          # bad
          string |> String.graphemes() |> length()
          length(String.graphemes(string))

          # good
          String.length(string)
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

    if graphemes_then_count?(steps) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(
         {:length, meta, [{{:., _, [{:__aliases__, _, [:String]}, :graphemes]}, _, [_]}]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :count]}, _,
          [{{:., _, [{:__aliases__, _, [:String]}, :graphemes]}, _, [_]}]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp graphemes_then_count?(steps) do
    Enum.chunk_every(steps, 2, 1, :discard)
    |> Enum.any?(fn [left, right] ->
      Ast.remote_call?(left, :String, :graphemes) and
        (Ast.local_call?(right, :length) or Ast.remote_call?(right, :Enum, :count))
    end)
  end

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message: "Use `String.length/1` instead of counting `String.graphemes/1`.",
      trigger: "String.graphemes",
      line_no: meta[:line]
    )
  end
end
