defmodule ExSlop.Check.Refactor.TryRescueWithSafeAlternative do
  use Credo.Check,
    id: "EXS4005",
    base_priority: :high,
    category: :refactor,
    tags: [:ex_slop],
    explanations: [
      check: """
      `try/rescue` around a function that has a non-raising equivalent
      is a sign the AI doesn't know Elixir's API.

          # bad
          try do
            String.to_integer(value)
          rescue
            _ -> nil
          end

          # good
          case Integer.parse(value) do
            {int, ""} -> int
            _ -> nil
          end

      Common pairs:

      | Raising                    | Safe alternative              |
      |----------------------------|-------------------------------|
      | `String.to_integer/1`      | `Integer.parse/1`             |
      | `String.to_float/1`        | `Float.parse/1`               |
      | `String.to_atom/1`         | `String.to_existing_atom/1`   |
      | `Jason.decode!/1`          | `Jason.decode/1`              |
      | `JSON.decode!/1`           | `JSON.decode/1`               |
      | `Map.fetch!/2`             | `Map.fetch/2`                 |
      | `Keyword.fetch!/2`         | `Keyword.fetch/2`             |
      | `Enum.fetch!/2`            | `Enum.fetch/2` / `Enum.at/2`  |
      | `File.read!/1`             | `File.read/1`                 |
      | `File.write!/2`            | `File.write/2`                |
      | `URI.parse/1` (old)        | `URI.new/1`                   |
      """
    ]

  @raising_functions %{
    {:String, :to_integer, 1} => "Integer.parse/1",
    {:String, :to_float, 1} => "Float.parse/1",
    {:String, :to_atom, 1} => "String.to_existing_atom/1",
    {:Jason, :decode!, 1} => "Jason.decode/1",
    {:Jason, :decode!, 2} => "Jason.decode/2",
    {:JSON, :decode!, 1} => "JSON.decode/1",
    {:Map, :fetch!, 2} => "Map.fetch/2",
    {:Keyword, :fetch!, 2} => "Keyword.fetch/2",
    {:Enum, :fetch!, 2} => "Enum.fetch/2 or Enum.at/2",
    {:File, :read!, 1} => "File.read/1",
    {:File, :write!, 2} => "File.write/2",
    {:File, :write!, 3} => "File.write/3"
  }

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # try do <call> rescue _ -> ... end
  defp walk({:try, meta, [[do: body, rescue: _clauses]]} = ast, ctx) do
    call = unwrap_body(body)

    case find_raising_call(call) do
      {raising, safe} ->
        {ast, put_issue(ctx, issue_for(ctx, meta, raising, safe))}

      nil ->
        {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp unwrap_body({:__block__, _, [single]}), do: single
  defp unwrap_body({:__block__, _, exprs}), do: last_expr(exprs)
  defp unwrap_body(other), do: other

  defp last_expr([expr]), do: expr
  defp last_expr([_ | rest]), do: last_expr(rest)

  # Module.function(args)
  defp find_raising_call({{:., _, [{:__aliases__, _, [mod]}, fun]}, _, args})
       when is_list(args) do
    key = {mod, fun, length(args)}

    case Map.fetch(@raising_functions, key) do
      {:ok, safe} -> {"#{mod}.#{fun}/#{length(args)}", safe}
      :error -> nil
    end
  end

  # Assignments: result = Module.function(args)
  defp find_raising_call({:=, _, [_lhs, rhs]}), do: find_raising_call(rhs)

  defp find_raising_call(_), do: nil

  defp issue_for(ctx, meta, raising, safe) do
    format_issue(ctx,
      message: "`try/rescue` around `#{raising}` — use `#{safe}` instead.",
      trigger: "try",
      line_no: meta[:line]
    )
  end
end
