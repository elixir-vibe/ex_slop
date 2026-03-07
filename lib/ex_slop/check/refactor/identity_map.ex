defmodule ExSlop.Check.Refactor.IdentityMap do
  use Credo.Check,
    id: "EXS4007",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      `Enum.map(fn x -> x end)` is an identity map that returns the list unchanged.

          # bad
          list |> Enum.map(fn x -> x end)
          Enum.map(list, fn item -> item end)

          # good — just remove it
          list
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # Enum.map(list, fn x -> x end)
  defp walk(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :map]}, _,
          [_enumerable, {:fn, _, [{:->, _, [[{var, _, ctx_a}], {var, _, ctx_b}]}]}]} = ast,
         ctx
       )
       when is_atom(var) and var != :{} and var != :%{} and is_atom(ctx_a) and is_atom(ctx_b) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  # list |> Enum.map(fn x -> x end)
  defp walk(
         {:|>, _,
          [
            _,
            {{:., meta, [{:__aliases__, _, [:Enum]}, :map]}, _,
             [{:fn, _, [{:->, _, [[{var, _, ctx_a}], {var, _, ctx_b}]}]}]}
          ]} = ast,
         ctx
       )
       when is_atom(var) and var != :{} and var != :%{} and is_atom(ctx_a) and is_atom(ctx_b) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "Identity `Enum.map` — the function returns its argument unchanged. Just remove it.",
      trigger: "map",
      line_no: meta[:line]
    )
  end
end
