defmodule ExSlop.Check.Refactor.ListLast do
  use Credo.Check,
    id: "EXS4024",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop, :credence],
    explanations: [
      check: """
      `List.last/1` traverses the whole list. Prefer structuring code so the needed value is already available.

          # bad
          List.last(items)

          # better when you control construction
          [last | _] = Enum.reverse(items)
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({{:., meta, [{:__aliases__, _, [:List]}, :last]}, _, [_list]} = ast, ctx) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "`List.last/1` is O(n); avoid needing the last element by restructuring the data flow when possible.",
      trigger: "List.last",
      line_no: meta[:line]
    )
  end
end
