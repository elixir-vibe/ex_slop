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

  defp filter_via_flat_map?({:fn, _, [{:->, _, [_args, body]}]}) do
    matches_singleton_list_pattern?(body)
  end

  defp filter_via_flat_map?({:fn, _, [{:->, _, [_args, [body]]}]}) do
    matches_singleton_list_pattern?(body)
  end

  defp filter_via_flat_map?(_), do: false

  # if cond, do: [expr], else: []
  defp matches_singleton_list_pattern?({:if, _, [_, [do: [_], else: []]]}), do: true
  defp matches_singleton_list_pattern?({:if, _, [_, [do: [], else: [_]]]}), do: true

  # Block form: if cond do [expr] else [] end
  defp matches_singleton_list_pattern?(
         {:if, _, [_, [do: {:__block__, _, [[_]]}, else: {:__block__, _, [[]]}]]}
       ),
       do: true

  defp matches_singleton_list_pattern?(
         {:if, _, [_, [do: {:__block__, _, [[]]}, else: {:__block__, _, [[_]]}]]}
       ),
       do: true

  defp matches_singleton_list_pattern?(_), do: false

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "`Enum.flat_map(fn x -> if cond, do: [x], else: [] end)` is `Enum.filter/2` — use filter directly.",
      trigger: "Enum.flat_map",
      line_no: meta[:line]
    )
  end
end
