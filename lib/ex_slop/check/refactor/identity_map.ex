defmodule ExSlop.Check.Refactor.IdentityMap do
  use Credo.Check,
    id: "EXS4007",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      `Enum.map(fn x -> x end)` is an identity map: every element is
      returned unchanged.

          # bad
          list |> Enum.map(fn x -> x end)
          Enum.map(list, fn item -> item end)

          # good — just remove it
          list

      Remember that `Enum.map/2` always returns a list. If the input may be
      another enumerable (a range, a `MapSet`, a stream), replace the call
      with `Enum.to_list/1` instead of removing it:

          # bad
          Enum.map(1..10, fn x -> x end)

          # good
          Enum.to_list(1..10)
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
        "Identity `Enum.map` — the function returns its argument unchanged. " <>
          "Remove it, or use `Enum.to_list/1` if the input is not already a list.",
      trigger: "map",
      line_no: meta[:line]
    )
  end
end
