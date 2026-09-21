defmodule ExSlop.Check.Refactor.FlatMapFilter do
  use Credo.Check,
    id: "EXS4015",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      `Enum.flat_map(list, fn x -> if cond, do: [x], else: [] end)` is just
      `Enum.filter/2` with extra steps.

          # bad — flat_map wrapping filter logic in singleton/empty lists
          Enum.flat_map(items, fn item ->
            if item.active, do: [item], else: []
          end)

          # good — use Enum.filter
          Enum.filter(items, & &1.active)

      Only reported when the singleton list holds the callback's argument
      unchanged. A callback that transforms the element is a legitimate
      `flat_map` (or a candidate for a `for` comprehension with a filter):

          # not flagged — the value is transformed
          Enum.flat_map(items, fn x -> if x > 0, do: [x * 2], else: [] end)
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # Enum.flat_map(list, fn x -> if cond, do: [x], else: [] end)
  defp walk(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :flat_map]}, _, [_list, fun]} = ast,
         ctx
       ) do
    if filter_via_flat_map?(fun) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  # |> Enum.flat_map(fn x -> if cond, do: [x], else: [] end)
  defp walk(
         {:|>, meta,
          [
            _,
            {{:., _, [{:__aliases__, _, [:Enum]}, :flat_map]}, _, [fun]}
          ]} = ast,
         ctx
       ) do
    if filter_via_flat_map?(fun) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  # fn x -> if cond, do: [x], else: [] end
  defp filter_via_flat_map?({:fn, _, [{:->, _, [[{var, _, context}], body]}]})
       when is_atom(var) and is_atom(context) do
    matches_singleton_list_pattern?(body, var)
  end

  defp filter_via_flat_map?(_), do: false

  # if cond, do: [x], else: []
  defp matches_singleton_list_pattern?({:if, _, [_, [do: [elem], else: []]]}, var),
    do: same_var?(elem, var)

  defp matches_singleton_list_pattern?({:if, _, [_, [do: [], else: [elem]]]}, var),
    do: same_var?(elem, var)

  # Block form: if cond do [x] else [] end
  defp matches_singleton_list_pattern?(
         {:if, _, [_, [do: {:__block__, _, [[elem]]}, else: {:__block__, _, [[]]}]]},
         var
       ),
       do: same_var?(elem, var)

  defp matches_singleton_list_pattern?(
         {:if, _, [_, [do: {:__block__, _, [[]]}, else: {:__block__, _, [[elem]]}]]},
         var
       ),
       do: same_var?(elem, var)

  defp matches_singleton_list_pattern?(_, _), do: false

  defp same_var?({var, _, context}, var) when is_atom(context), do: true
  defp same_var?(_, _), do: false

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "`Enum.flat_map(fn x -> if cond, do: [x], else: [] end)` is `Enum.filter/2` — use filter directly.",
      trigger: "Enum.flat_map",
      line_no: meta[:line]
    )
  end
end
