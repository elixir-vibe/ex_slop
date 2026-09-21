defmodule ExSlop.Check.Refactor.IdentityPassthrough do
  use Credo.Check,
    id: "EXS4004",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      A `case` that matches patterns only to return the same thing is a
      no-op — just return the value directly.

          # bad — identity passthrough
          case result do
            {:ok, value} -> {:ok, value}
            other -> other
          end

          # good
          result

      Note that a `case` without a catch-all clause raises `CaseClauseError`
      for values it does not match, while returning the value directly does
      not. Such a `case` is still reported — it is far more common in
      generated code than in hand-written code — but if raising on
      unexpected shapes is the point, say so with an explicit clause rather
      than relying on the identity `case`.

      Map and struct patterns are never treated as identity, because they
      match extra keys that the rebuilt map drops:

          # not flagged — this is a projection, not a passthrough
          case value do
            %{a: a} -> %{a: a}
            %{b: b} -> %{b: b}
          end
      """
    ]

  alias Credo.Code
  alias ExSlop.Ast

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # case expr do pattern1 -> pattern1; pattern2 -> pattern2 end
  defp walk({:case, meta, [_expr, [do: clauses]]} = ast, ctx) when is_list(clauses) do
    if multiple_clauses?(clauses) and Enum.all?(clauses, &Ast.identity_clause?/1) do
      exhaustive? = Enum.any?(clauses, &Ast.catch_all_clause?/1)
      {ast, put_issue(ctx, issue_for(ctx, meta, exhaustive?))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp multiple_clauses?([_, _ | _]), do: true
  defp multiple_clauses?(_), do: false

  defp issue_for(ctx, meta, exhaustive?) do
    format_issue(ctx,
      message: message(exhaustive?),
      trigger: "case",
      line_no: meta[:line]
    )
  end

  defp message(true),
    do: "Identity `case` — every clause returns what it matched. Just return the value."

  defp message(false),
    do:
      "Identity `case` — every clause returns what it matched. Return the value directly; " <>
        "if raising on other shapes is intended, add an explicit clause that raises."
end
