defmodule ExSlop.Check.Refactor.WithIdentityDo do
  use Credo.Check,
    id: "EXS4010",
    base_priority: :normal,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      A `with` whose `do` block just returns the matched pattern is redundant —
      use the expression directly.

          # bad — identity do
          with {:ok, result} <- do_something() do
            {:ok, result}
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
    with [clause] <- arrow_clauses(args),
         false <- has_else?(args),
         true <- identity_do?(clause, args) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      _ -> {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp arrow_clauses(args) do
    Enum.filter(args, fn
      {:<-, _meta, _} -> true
      _ -> false
    end)
  end

  defp has_else?(args) do
    case last_arg(args) do
      kw when is_list(kw) -> Keyword.has_key?(kw, :else)
      _ -> false
    end
  end

  defp identity_do?(clause, args) do
    {:<-, _meta, [pattern, _expr]} = clause

    case last_arg(args) do
      kw when is_list(kw) ->
        body = Keyword.get(kw, :do)

        Code.remove_metadata(pattern) == Code.remove_metadata(body)

      _ ->
        false
    end
  end

  defp last_arg([arg]), do: arg
  defp last_arg([_ | rest]), do: last_arg(rest)

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "Identity `with` — the `do` block returns what the `<-` matched. Just use the expression directly.",
      trigger: "with",
      line_no: meta[:line]
    )
  end
end
