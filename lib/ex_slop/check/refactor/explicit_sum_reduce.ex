defmodule ExSlop.Check.Refactor.ExplicitSumReduce do
  use Credo.Check,
    id: "EXS4026",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop, :credence],
    explanations: [
      check: """
      `Enum.reduce/3` that only sums values should usually be `Enum.sum/1`.

          # bad
          Enum.reduce(nums, 0, fn num, acc -> num + acc end)

          # good
          Enum.sum(nums)
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({{:., meta, [{:__aliases__, _, [:Enum]}, :reduce]}, _, [_enum, 0, fun]} = ast, ctx) do
    if sum_fun?(fun) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(
         {:|>, _, [_, {{:., meta, [{:__aliases__, _, [:Enum]}, :reduce]}, _, [0, fun]}]} = ast,
         ctx
       ) do
    if sum_fun?(fun) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp sum_fun?(
         {:fn, _,
          [{:->, _, [[{left, _, _}, {right, _, _}], {:+, _, [{left, _, _}, {right, _, _}]}]}]}
       ),
       do: true

  defp sum_fun?(
         {:fn, _,
          [{:->, _, [[{left, _, _}, {right, _, _}], {:+, _, [{right, _, _}, {left, _, _}]}]}]}
       ),
       do: true

  defp sum_fun?(_), do: false

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message: "Use `Enum.sum/1` instead of an explicit summing `Enum.reduce/3`.",
      trigger: "Enum.reduce",
      line_no: meta[:line]
    )
  end
end
