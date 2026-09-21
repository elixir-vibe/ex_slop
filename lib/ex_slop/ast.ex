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

  # Map and struct patterns match partially, so rebuilding them drops keys.
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
