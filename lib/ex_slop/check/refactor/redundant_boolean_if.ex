defmodule ExSlop.Check.Refactor.RedundantBooleanIf do
  use Credo.Check,
    id: "EXS4014",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      `if condition, do: true, else: false` is redundant — the condition
      already evaluates to a boolean (or can be made one with `!!`).

          # bad — wrapping a boolean condition in if/true/false
          is_active = if status == :active, do: true, else: false
          if !is_nil(x) and !is_nil(y), do: true, else: false

          # good — use the expression directly
          is_active = status == :active
          !is_nil(x) and !is_nil(y)
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # if cond, do: true, else: false
  defp walk({:if, meta, [_cond, [do: true, else: false]]} = ast, ctx) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  # if cond, do: false, else: true  (negated)
  defp walk({:if, meta, [_cond, [do: false, else: true]]} = ast, ctx) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  # if cond do true else false end (keyword list form)
  defp walk(
         {:if, meta, [_cond, [do: {:__block__, _, [true]}, else: {:__block__, _, [false]}]]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message: "`if condition, do: true, else: false` is redundant — use the condition directly.",
      trigger: "if",
      line_no: meta[:line]
    )
  end
end
