defmodule ExSlop.Ast do
  @moduledoc false

  def remote_call?({{:., _, [{:__aliases__, _, [module]}, function]}, _, args}, module, function)
      when is_list(args),
      do: true

  def remote_call?(_, _, _), do: false

  def local_call?({function, _, args}, function) when is_atom(function) and is_list(args),
    do: true

  def local_call?(_, _), do: false

  def pipeline_steps({:|>, _, [left, right]}), do: pipeline_steps(left) ++ [right]
  def pipeline_steps(ast), do: [ast]

  # `pattern -> pattern` — the body rebuilds exactly what was matched.
  # Map and struct patterns are excluded: they match partially, so
  # rebuilding them drops keys.
  def identity_clause?({:->, _meta, [[pattern], body]}) do
    not contains_map?(pattern) and
      Credo.Code.remove_metadata(pattern) == Credo.Code.remove_metadata(body)
  end

  def identity_clause?(_), do: false

  # `other -> ...` — a bare variable pattern that matches anything.
  def catch_all_clause?({:->, _meta, [[{name, _, context}], _body]})
      when is_atom(name) and is_atom(context),
      do: true

  def catch_all_clause?(_), do: false

  def contains_map?(ast) do
    contains?(ast, fn
      {:%{}, _, _} -> true
      {:%, _, _} -> true
      _ -> false
    end)
  end

  def contains?(ast, predicate) do
    {_ast, found?} =
      Macro.prewalk(ast, false, fn node, found? ->
        {node, found? or predicate.(node)}
      end)

    found?
  end
end
