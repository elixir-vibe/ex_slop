defmodule ExSlop.Check.Warning.RescueWithoutReraise do
  use Credo.Check,
    id: "EXS1004",
    base_priority: :normal,
    category: :warning,
    tags: [:ex_slop],
    explanations: [
      check: """
      A `rescue` that logs the error but doesn't re-raise or return it
      silently swallows failures. Callers will never know something went wrong.

          # bad — logs then returns a generic atom
          rescue
            e ->
              Logger.error("Failed: \#{inspect(e)}")
              :error

          # good — log and re-raise
          rescue
            e ->
              Logger.error("Failed: \#{Exception.message(e)}")
              reraise e, __STACKTRACE__

          # good — return the actual exception info
          rescue
            e in RuntimeError ->
              {:error, Exception.message(e)}
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:try, _, [blocks]} = ast, ctx) when is_list(blocks) do
    clauses = Keyword.get(blocks, :rescue, [])
    {ast, Enum.reduce(clauses, ctx, &check_clause/2)}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp check_clause({:->, meta, [[{name, _, _}], body]}, ctx) when is_atom(name) do
    name_str = Atom.to_string(name)

    if not String.starts_with?(name_str, "_") and has_logger_call?(body) and
         not has_reraise?(body) and
         returns_generic?(body) do
      put_issue(ctx, issue_for(ctx, meta))
    else
      ctx
    end
  end

  defp check_clause(_, ctx), do: ctx

  defp has_logger_call?(ast) do
    {_, found?} =
      Macro.prewalk(ast, false, fn
        {{:., _, [{:__aliases__, _, [:Logger]}, _]}, _, _} = node, _ -> {node, true}
        node, found -> {node, found}
      end)

    found?
  end

  defp has_reraise?(ast) do
    {_, found?} =
      Macro.prewalk(ast, false, fn
        {:reraise, _, _} = node, _ -> {node, true}
        node, found -> {node, found}
      end)

    found?
  end

  defp returns_generic?({:__block__, _, exprs}), do: generic_return?(last_expr(exprs))
  defp returns_generic?(expr), do: generic_return?(expr)

  defp last_expr([expr]), do: expr
  defp last_expr([_ | rest]), do: last_expr(rest)

  defp generic_return?(:error), do: true
  defp generic_return?({:__block__, _, [:error]}), do: true
  defp generic_return?({:error, _}), do: true
  defp generic_return?({:{}, _, [:error | _]}), do: true
  defp generic_return?(nil), do: true
  defp generic_return?({:__block__, _, [nil]}), do: true
  defp generic_return?(_), do: false

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message: "`rescue` logs the error but swallows it — re-raise or return the exception info.",
      trigger: "rescue",
      line_no: meta[:line]
    )
  end
end
