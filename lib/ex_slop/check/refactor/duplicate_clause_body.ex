defmodule ExSlop.Check.Refactor.DuplicateClauseBody do
  use Credo.Check,
    id: "EXS4016",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      Multiple function clauses with identical arguments and bodies but
      different guards should be combined using `or` in a single clause.

          # bad — two clauses with identical args and body, only guards differ
          defp sanitize(error) when is_struct(error) do
            Sanitize.message(error)
          end

          defp sanitize(error) when is_atom(error) do
            Sanitize.message(error)
          end

          # good — combine guards
          defp sanitize(error) when is_struct(error) or is_atom(error) do
            Sanitize.message(error)
          end
      """
    ]

  @min_clauses 2

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)

    source_file
    |> Credo.Code.prewalk(&collect_defps/2, [])
    |> group_by_name_arity()
    |> Enum.flat_map(&find_duplicates/1)
    |> Enum.reduce(ctx, fn {meta, fun_name, arity}, acc ->
      put_issue(acc, issue_for(acc, meta, fun_name, arity))
    end)
    |> Map.get(:issues)
  end

  defp collect_defps({:defp, meta, _args} = ast, acc) do
    {ast, [{meta, ast} | acc]}
  end

  defp collect_defps(ast, acc), do: {ast, acc}

  defp group_by_name_arity(clauses) do
    clauses
    |> Enum.reverse()
    |> Enum.group_by(fn {_meta, ast} -> {fun_name(ast), fun_arity(ast)} end)
    |> Map.values()
  end

  defp find_duplicates(clauses) when length(clauses) < @min_clauses, do: []

  defp find_duplicates(clauses) do
    parsed =
      clauses
      |> Enum.map(fn {meta, ast} ->
        {meta, fun_name(ast), fun_arity(ast), arguments(ast), guard(ast), body(ast)}
      end)

    parsed
    |> Enum.with_index()
    |> Enum.flat_map(fn {{meta, name, arity, args1, guard1, body1}, idx} ->
      parsed
      |> Enum.drop(idx + 1)
      |> Enum.filter(fn {_m, _n, _a, args2, guard2, body2} ->
        args2 == args1 and body2 == body1 and guard1 != nil and guard2 != nil and
          guard1 != guard2
      end)
      |> Enum.map(fn _ -> {meta, name, arity} end)
    end)
    |> Enum.take(1)
  end

  defp fun_name({:defp, _, [{:when, _, [{name, _, _} | _]}, _]}), do: name
  defp fun_name({:defp, _, [{name, _, _}, _]}), do: name
  defp fun_name({:defp, _, [{name, _, _}]}), do: name
  defp fun_name(_), do: nil

  defp fun_arity({:defp, _, [{:when, _, [{_, _, args} | _]}, _]}) when is_list(args),
    do: length(args)

  defp fun_arity({:defp, _, [{_, _, args}, _]}) when is_list(args), do: length(args)
  defp fun_arity(_), do: nil

  defp arguments({:defp, _, [{:when, _, [{_, _, args} | _]}, _]}) when is_list(args) do
    Enum.map(args, &normalize_ast/1)
  end

  defp arguments({:defp, _, [{_, _, args}, _]}) when is_list(args) do
    Enum.map(args, &normalize_ast/1)
  end

  defp arguments(_), do: nil

  defp guard({:defp, _, [{:when, _, [_call, guard]}, _]}), do: normalize_ast(guard)
  defp guard(_), do: nil

  defp body({:defp, _, [_call, [do: body]]}), do: normalize_ast(body)
  defp body(_), do: nil

  defp normalize_ast(ast) do
    Macro.prewalk(ast, fn
      {form, _meta, args} -> {form, nil, args}
      other -> other
    end)
  end

  defp issue_for(ctx, meta, name, arity) do
    format_issue(ctx,
      message: "Function clauses for `#{name}/#{arity}` have identical arguments and bodies — combine guards with `or`.",
      trigger: to_string(name),
      line_no: meta[:line]
    )
  end
end
