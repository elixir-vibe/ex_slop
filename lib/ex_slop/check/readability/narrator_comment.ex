defmodule ExSlop.Check.Readability.NarratorComment do
  use Credo.Check,
    id: "EXS3008",
    base_priority: :low,
    category: :readability,
    tags: [:ex_slop],
    explanations: [
      check: """
      Inline comments that narrate code in first-person plural ("we") or
      with "Let's" / "Here we" are a hallmark of LLM-generated code.
      They add no value — either delete them or replace with a comment
      that explains WHY.

          # bad
          # Here we fetch the user from the database
          user = Repo.get!(User, id)

          # Now we validate the input
          changeset = User.changeset(user, attrs)

          # Let's create a new changeset
          changeset = change(user)

          # good — no comment needed, the code is clear

          # good — explains WHY
          # Bypass validation for admin imports (they're pre-validated upstream)
          Repo.insert!(changeset, skip_validations: true)
      """
    ]

  @narrator_starts [
    "Here we",
    "Now we",
    "Let's",
    "Lets",
    "Next we",
    "Next, we",
    "Finally we",
    "Finally, we",
    "First we",
    "First, we"
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

  @explanation_indicators [
    "because",
    "since",
    "due to",
    "avoid",
    "prevent",
    "otherwise",
    "in order",
    "so that",
    "so we",
    "ensure",
    "in case",
    "necessary",
    "need to handle",
    "workaround",
    "cannot",
    "can't",
    "shouldn't",
    "must not",
    "not supported",
    "bootstrap",
    "compat"
  ]

  @max_length 60

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

      if not DocRanges.inside_doc?(line_no, doc_ranges) and narrator?(trimmed) do
        put_issue(ctx, issue_for(ctx, line_no))
      else
        ctx
      end
    end)
    |> Map.get(:issues, [])
  end

  defp narrator?(line) do
    comment_body = extract_comment_body(line)

    comment_body != nil and
      String.length(comment_body) <= @max_length and
      narrator_start?(comment_body) and
      not keeper_keyword?(line) and
      not tool_directive?(line) and
      not explanation?(comment_body)
  end

  defp narrator_start?(comment) do
    trimmed = String.trim_leading(comment)

    Enum.any?(@narrator_starts, &String.starts_with?(trimmed, &1))
  end

  defp keeper_keyword?(line) do
    Enum.any?(@keeper_keywords, &String.contains?(line, &1))
  end

  defp tool_directive?(line) do
    Enum.any?(@tool_keywords, &String.contains?(line, &1))
  end

  defp explanation?(comment) do
    Enum.any?(@explanation_indicators, &String.contains?(comment, &1))
  end

  defp extract_comment_body(line) do
    trimmed = String.trim_leading(line)

    case trimmed do
      "#" <> rest -> String.trim_leading(rest)
      _ -> nil
    end
  end

  defp issue_for(ctx, line_no) do
    format_issue(ctx,
      message: "Narrator comment ('We need to...', 'Here we...') — either remove or explain WHY.",
      trigger: "#",
      line_no: line_no
    )
  end
end
