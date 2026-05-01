defmodule ExSlop.Check.Refactor.ListFold do
  use Credo.Check,
    id: "EXS4023",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop, :credence],
    explanations: [
      check: """
      Prefer `Enum.reduce/3` over Erlang-style `List.foldl/3` and `List.foldr/3`.

          # bad
          List.foldl(items, 0, fn item, acc -> item + acc end)

          # good
          Enum.reduce(items, 0, fn item, acc -> item + acc end)
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({{:., meta, [{:__aliases__, _, [:List]}, function]}, _, [_, _, _]} = ast, ctx)
       when function in [:foldl, :foldr] do
    {ast, put_issue(ctx, issue_for(ctx, meta, function))}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp issue_for(ctx, meta, function) do
    format_issue(ctx,
      message: "Prefer `Enum.reduce/3` over `List.#{function}/3` for idiomatic Elixir.",
      trigger: "List.#{function}",
      line_no: meta[:line]
    )
  end
end
