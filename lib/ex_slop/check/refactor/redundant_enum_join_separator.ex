defmodule ExSlop.Check.Refactor.RedundantEnumJoinSeparator do
  use Credo.Check,
    id: "EXS4016",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop, :credence],
    explanations: [
      check: """
      `Enum.join(enum, "")` is the same as `Enum.join(enum)`.

          # bad
          Enum.join(parts, "")
          parts |> Enum.join("")

          # good
          Enum.join(parts)
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({{:., meta, [{:__aliases__, _, [:Enum]}, :join]}, _, [_enum, ""]} = ast, ctx) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(
         {:|>, _, [left, {{:., meta, [{:__aliases__, _, [:Enum]}, :join]}, _, [""]}]} = ast,
         ctx
       ) do
    if ExSlop.Ast.remote_call?(rightmost_pipeline_step(left), :Enum, :map) do
      {ast, ctx}
    else
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp rightmost_pipeline_step({:|>, _, [_left, right]}), do: right
  defp rightmost_pipeline_step(ast), do: ast

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "`Enum.join/1` already defaults to an empty string separator — remove the redundant `\"\"`.",
      trigger: "Enum.join",
      line_no: meta[:line]
    )
  end
end
