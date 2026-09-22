defmodule ExSlop.Check.Refactor.WithIdentityElse do
  use Credo.Check,
    id: "EXS4008",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      A `with` whose `else` clauses all return exactly what they matched
      is redundant — remove the `else` block entirely.

          # bad — identity else
          with {:ok, result} <- do_something() do
            {:ok, result}
          else
            {:error, reason} -> {:error, reason}
          end

          # good
          do_something()

      Note that an `else` without a catch-all clause raises `WithClauseError`
      for values it does not match, while a `with` without `else` returns
      them as-is. Such an `else` is still reported — it is far more common in
      generated code than in hand-written code — but if raising on
      unexpected values is the point, say so with an explicit clause rather
      than relying on the identity `else`.

      Map and struct patterns are never treated as identity, because they
      match extra keys that the rebuilt map drops.
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

  defp walk({:with, meta, args} = ast, ctx) when is_list(args) do
    with {:ok, clauses} <- else_clauses(args),
         true <- clauses != [] and Enum.all?(clauses, &Ast.identity_clause?/1) do
      exhaustive? = Enum.any?(clauses, &Ast.catch_all_clause?/1)
      {ast, put_issue(ctx, issue_for(ctx, meta, exhaustive?))}
    else
      _ -> {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp else_clauses(args) do
    case last_arg(args) do
      kw when is_list(kw) ->
        if Keyword.has_key?(kw, :else), do: {:ok, kw[:else]}, else: :error

      _ ->
        :error
    end
  end

  defp last_arg([arg]), do: arg
  defp last_arg([_ | rest]), do: last_arg(rest)

  defp issue_for(ctx, meta, exhaustive?) do
    format_issue(ctx,
      message: message(exhaustive?),
      trigger: "with",
      line_no: meta[:line]
    )
  end

  defp message(true),
    do:
      "Identity `else` in `with` — every clause returns what it matched. The `else` block is redundant."

  defp message(false),
    do:
      "Identity `else` in `with` — every clause returns what it matched. Remove the `else`; " <>
        "if raising on other values is intended, add an explicit clause that raises."
end
