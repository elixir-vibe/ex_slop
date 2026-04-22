defmodule ExSlop.Check.Readability.BoilerplateDocParams do
  use Credo.Check,
    id: "EXS3007",
    base_priority: :low,
    category: :readability,
    tags: [:ex_slop],
    explanations: [
      check: """
      `@doc` strings with a `## Parameters` section that merely restates
      the function signature add no value.

          # bad
          @doc \"""
          Renders the index page.

          ## Parameters

          - conn: The connection struct
          - params: A map of parameters
          \"""
          def index(conn, params)

          # good — document constraints, not names
          @doc \"""
          Renders the index page.

          ## Parameters

          - params: Must include `"page"` (integer >= 1) and
            optionally `"per_page"` (default 20, max 100).
          \"""

          # good — no ## Parameters section at all
          @doc \"""
          Renders the index page, paginated.
          \"""
      """
    ]

  @section_headings ["## Parameters", "## Params", "## Arguments", "## Args"]

  @boilerplate_params ["conn", "params", "socket", "assigns"]
  @boilerplate_descriptions [
    "connection",
    "map of param",
    "socket",
    "assigns"
  ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:@, _, [{:doc, meta, [docstring]}]} = ast, ctx) when is_binary(docstring) do
    if boilerplate_params?(docstring) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp boilerplate_params?(docstring) do
    has_section_heading?(docstring) and has_boilerplate_entry?(docstring)
  end

  defp has_section_heading?(docstring) do
    Enum.any?(@section_headings, &String.contains?(docstring, &1))
  end

  defp has_boilerplate_entry?(docstring) do
    docstring
    |> String.split("\n")
    |> Enum.any?(&boilerplate_line?/1)
  end

  defp boilerplate_line?(line) do
    trimmed = String.trim(line)

    if String.starts_with?(trimmed, "-") do
      content = String.trim_leading(trimmed, "-") |> String.trim()

      param_match =
        Enum.any?(@boilerplate_params, fn param ->
          String.starts_with?(content, param) or String.starts_with?(content, "`#{param}`")
        end)

      desc_match =
        Enum.any?(@boilerplate_descriptions, fn desc ->
          String.contains?(String.downcase(content), desc)
        end)

      param_match and desc_match
    else
      false
    end
  end

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "Boilerplate `## Parameters` doc restates the function signature — document constraints or remove it.",
      trigger: "@doc",
      line_no: meta[:line]
    )
  end
end
