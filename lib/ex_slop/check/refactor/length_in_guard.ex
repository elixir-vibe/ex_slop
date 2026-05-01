defmodule ExSlop.Check.Refactor.LengthInGuard do
  use Credo.Check,
    id: "EXS4025",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop, :credence],
    explanations: [
      check: """
      `length/1` in guards traverses the list whenever the clause is considered.

          # bad
          def empty?(list) when length(list) == 0, do: true

          # good
          def empty?([]), do: true
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:when, meta, [_head, guard]} = ast, ctx) do
    if ExSlop.Ast.contains?(guard, &length_call?/1) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp length_call?({:length, _, [_]}), do: true
  defp length_call?(_), do: false

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "Avoid `length/1` in guards; use pattern matching such as `[]` or `[_ | _]` instead.",
      trigger: "length",
      line_no: meta[:line]
    )
  end
end
