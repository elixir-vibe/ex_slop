defmodule ExSlop.Check.Readability.ObviousComment do
  use Credo.Check,
    id: "EXS3003",
    base_priority: :low,
    category: :readability,
    tags: [:ex_slop],
    explanations: [
      check: """
      Comments that restate what the next line of code does are noise.
      This check only flags very short comments (under 60 chars) that
      start with a verb + article and contain no technical detail.

          # bad
          # Fetch the user
          user = Repo.get(User, id)

          # Create the changeset
          changeset = User.changeset(user, attrs)

          # Return the result
          {:ok, changeset}

          # good — no comment needed, the code is clear

          # good — explains HOW or WHY (not flagged despite starting with "Fetch")
          # Fetch the connection from the pool, blocking up to 5s
          conn = ConnectionPool.checkout!(pool, timeout: 5_000)
      """
    ]

  @obvious_pattern ~r/\A\s*#\s*(?:Fetch|Get|Create|Build|Update|Delete|Remove|Set|Parse|Convert|Validate|Check|Process|Handle|Format|Transform|Normalize|Calculate|Compute|Extract|Initialize|Define|Assign|Store|Save|Insert|Add|Return|Ensure|Verify)\s+(?:the|a|an)\s/i

  @keeper_pattern ~r/\bTODO\b|\bFIXME\b|\bHACK\b|\bNOTE\b|\bSAFETY\b|\bWARN\b|\bBUG\b|\bXXX\b|\bPERF\b/

  @tool_directive ~r/credo:|dialyzer:|sobelow:|coveralls|noinspection|elixir-ls|ExUnit/

  @max_obvious_length 60

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)

    source_file
    |> Credo.SourceFile.lines()
    |> Enum.reduce(ctx, fn {line_no, line}, ctx ->
      trimmed = String.trim(line)

      if obvious?(trimmed) do
        put_issue(ctx, issue_for(ctx, line_no))
      else
        ctx
      end
    end)
    |> Map.get(:issues, [])
  end

  defp obvious?(line) do
    comment_body = extract_comment_body(line)

    comment_body != nil and
      String.length(comment_body) < @max_obvious_length and
      Regex.match?(@obvious_pattern, line) and
      not has_technical_detail?(comment_body) and
      not Regex.match?(@keeper_pattern, line) and
      not Regex.match?(@tool_directive, line)
  end

  defp extract_comment_body(line) do
    case Regex.run(~r/\A\s*#\s*(.+)/, line) do
      [_, body] -> body
      _ -> nil
    end
  end

  defp has_technical_detail?(comment) do
    Regex.match?(
      ~r/\d|timeout|blocking|because|since|due to|avoid|prevent|N\+1|O\(|concurrent|async|idempotent/i,
      comment
    )
  end

  defp issue_for(ctx, line_no) do
    format_issue(ctx,
      message: "Obvious comment restates what the code does — remove it or explain WHY.",
      trigger: "#",
      line_no: line_no
    )
  end
end
