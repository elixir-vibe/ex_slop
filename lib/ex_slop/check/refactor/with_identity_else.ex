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
      """
    ]

  alias Credo.Code

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:with, meta, args} = ast, ctx) when is_list(args) do
    with {:ok, clauses} <- else_clauses(args),
         true <- clauses != [] and Enum.all?(clauses, &identity_clause?/1) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
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

  defp identity_clause?({:->, _meta, [[pattern], body]}) do
    Code.remove_metadata(pattern) == Code.remove_metadata(body)
  end

  defp identity_clause?(_), do: false

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "Identity `else` in `with` — every clause returns what it matched. The `else` block is redundant.",
      trigger: "with",
      line_no: meta[:line]
    )
  end
end
