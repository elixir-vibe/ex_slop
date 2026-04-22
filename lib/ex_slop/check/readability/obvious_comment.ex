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

  @obvious_verbs [
    "Fetch",
    "Get",
    "Create",
    "Build",
    "Update",
    "Delete",
    "Remove",
    "Set",
    "Parse",
    "Convert",
    "Validate",
    "Check",
    "Process",
    "Handle",
    "Format",
    "Transform",
    "Normalize",
    "Calculate",
    "Compute",
    "Extract",
    "Initialize",
    "Define",
    "Assign",
    "Store",
    "Save",
    "Insert",
    "Add",
    "Return",
    "Ensure",
    "Verify"
  ]

  @keeper_keywords ["TODO", "FIXME", "HACK", "NOTE", "SAFETY", "WARN", "BUG", "XXX", "PERF"]

  @tool_keywords [
    "credo:",
    "dialyzer:",
    "sobelow:",
    "coveralls",
    "noinspection",
    "elixir-ls",
    "ExUnit"
  ]

  @max_obvious_length 60

  alias Credo.SourceFile
  alias ExSlop.DocRanges

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    doc_ranges = DocRanges.build(SourceFile.source(source_file))

    source_file
    |> SourceFile.lines()
    |> Enum.reduce(ctx, fn {line_no, line}, ctx ->
      trimmed = String.trim(line)

      if not DocRanges.inside_doc?(line_no, doc_ranges) and obvious?(trimmed) do
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
      obvious_verb_article?(comment_body) and
      not has_technical_detail?(comment_body) and
      not keeper_keyword?(line) and
      not tool_directive?(line)
  end

  defp obvious_verb_article?(comment) do
    Enum.any?(@obvious_verbs, fn verb ->
      case String.split(comment, " ", parts: 3) do
        [^verb, article | _] when article in ["the", "a", "an"] -> true
        _ -> false
      end
    end)
  end

  defp keeper_keyword?(line) do
    Enum.any?(@keeper_keywords, &String.contains?(line, &1))
  end

  defp tool_directive?(line) do
    Enum.any?(@tool_keywords, &String.contains?(line, &1))
  end

  defp extract_comment_body(line) do
    trimmed = String.trim_leading(line)

    case trimmed do
      "#" <> rest -> String.trim_leading(rest)
      _ -> nil
    end
  end

  @technical_indicators [
    "timeout",
    "blocking",
    "because",
    "since",
    "due to",
    "avoid",
    "prevent",
    "N+1",
    "O(",
    "concurrent",
    "async",
    "idempotent",
    "so that",
    "so we",
    "otherwise",
    "in order",
    "necessary",
    "compat",
    "bootstrap",
    "by hand",
    "workaround",
    "cannot",
    "can't",
    "shouldn't",
    "must not",
    "not supported"
  ]

  defp has_technical_detail?(comment) do
    has_digit = Enum.any?(?0..?9, &String.contains?(comment, <<&1>>))
    has_indicator = Enum.any?(@technical_indicators, &String.contains?(comment, &1))

    has_digit or has_indicator
  end

  defp issue_for(ctx, line_no) do
    format_issue(ctx,
      message: "Obvious comment restates what the code does — remove it or explain WHY.",
      trigger: "#",
      line_no: line_no
    )
  end
end
