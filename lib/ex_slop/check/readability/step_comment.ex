defmodule ExSlop.Check.Readability.StepComment do
  use Credo.Check,
    id: "EXS3004",
    base_priority: :low,
    category: :readability,
    tags: [:ex_slop],
    explanations: [
      check: """
      "Step 1: ..." comments indicate the function is doing too much.
      Extract each step into its own well-named function.

          # bad
          def process(data) do
            # Step 1: Validate the input
            validated = validate(data)
            # Step 2: Transform the data
            transformed = transform(validated)
            # Step 3: Save to database
            save(transformed)
          end

          # good — the pipe IS the steps
          def process(data) do
            data
            |> validate()
            |> transform()
            |> save()
          end
      """
    ]

  @step_prefixes ["STEP ", "Step ", "step "]

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
      if not DocRanges.inside_doc?(line_no, doc_ranges) and
           step_comment?(String.trim(line)) do
        put_issue(ctx, issue_for(ctx, line_no))
      else
        ctx
      end
    end)
    |> Map.get(:issues, [])
  end

  defp step_comment?(line) do
    trimmed = String.trim_leading(line)

    case trimmed do
      "#" <> rest ->
        rest = String.trim_leading(rest)
        Enum.any?(@step_prefixes, &String.starts_with?(rest, &1))

      _ ->
        false
    end
  end

  defp issue_for(ctx, line_no) do
    format_issue(ctx,
      message: "\"Step N:\" comment — extract each step into a well-named function instead.",
      trigger: "#",
      line_no: line_no
    )
  end
end
