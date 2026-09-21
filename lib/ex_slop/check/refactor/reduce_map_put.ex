defmodule ExSlop.Check.Refactor.ReduceMapPut do
  use Credo.Check,
    id: "EXS4013",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      `Enum.reduce(%{}, fn x, acc -> Map.put(acc, key, value) end)` is
      `Map.new/2` (or a `for` comprehension).

          # bad — verbose reduce to build a map
          Enum.reduce(batch, %{}, fn event, acc ->
            Map.put(acc, event.id, event)
          end)

          # good — use Map.new
          Map.new(batch, fn event -> {event.id, event} end)

          # good — for comprehension
          for event <- batch, into: %{}, do: {event.id, event}

      Reductions whose key or value read the accumulator are not reported,
      because `Map.new/2` cannot express them:

          # not flagged — the value depends on the accumulator
          Enum.reduce(entries, %{}, fn {key, amount}, acc ->
            Map.put(acc, key, Map.get(acc, key, 0) + amount)
          end)
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # Enum.reduce(list, %{}, fn x, acc -> Map.put(acc, k, v) end)
  defp walk(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :reduce]}, _, [_, {:%{}, _, []}, fun]} = ast,
         ctx
       ) do
    if fn_body_is_only_map_put?(fun) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  # |> Enum.reduce(%{}, fn x, acc -> Map.put(acc, k, v) end)
  defp walk(
         {:|>, meta,
          [
            _,
            {{:., _, [{:__aliases__, _, [:Enum]}, :reduce]}, _, [{:%{}, _, []}, fun]}
          ]} = ast,
         ctx
       ) do
    if fn_body_is_only_map_put?(fun) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp fn_body_is_only_map_put?({:fn, _, [{:->, _, [[_arg, acc], body]}]}) do
    body_is_map_put?(body, acc)
  end

  defp fn_body_is_only_map_put?({:fn, _, [{:->, _, [[_arg, acc], [body]]}]}) do
    body_is_map_put?(body, acc)
  end

  defp fn_body_is_only_map_put?(_), do: false

  # Map.put(acc, key, value) where neither key nor value reads acc
  defp body_is_map_put?(
         {{:., _, [{:__aliases__, _, [:Map]}, :put]}, _, [{acc_name, _, _}, key, value]},
         {acc_name, _, _}
       )
       when is_atom(acc_name) do
    not references_var?(key, acc_name) and not references_var?(value, acc_name)
  end

  defp body_is_map_put?({:__block__, _, [expr]}, acc), do: body_is_map_put?(expr, acc)
  defp body_is_map_put?(_, _), do: false

  defp references_var?(ast, name) do
    ExSlop.Ast.contains?(ast, fn
      {^name, _, context} when is_atom(context) -> true
      _ -> false
    end)
  end

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "Use `Map.new/2` or `for ... into: %{}` instead of `Enum.reduce(%{}, ..., Map.put/3)`.",
      trigger: "Enum.reduce",
      line_no: meta[:line]
    )
  end
end
