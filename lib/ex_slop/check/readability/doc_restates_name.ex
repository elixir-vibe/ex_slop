defmodule ExSlop.Check.Readability.DocRestatesName do
  use Credo.Check,
    id: "EXS3002",
    base_priority: :low,
    category: :readability,
    tags: [:ex_slop],
    explanations: [
      check: """
      One-liner `@doc` that just restates the function name adds no value.

          # bad — "Creates a user" on `create_user/1`
          @doc "Creates a new user."
          def create_user(attrs)

          @doc "Deletes the given post."
          def delete_post(post)

          # good — explains constraints or behavior
          @doc "Soft-deletes by setting `deleted_at`; can be undone within 30 days."
          def delete_post(post)

          # good — just omit the doc entirely
          def create_user(attrs)
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)

    source_file
    |> Credo.SourceFile.ast()
    |> collect_doc_def_pairs()
    |> Enum.reduce(ctx, fn {docstring, meta, fun_name}, ctx ->
      if restates_name?(docstring, fun_name) do
        put_issue(ctx, issue_for(ctx, meta))
      else
        ctx
      end
    end)
    |> Map.get(:issues, [])
  end

  defp collect_doc_def_pairs(ast) do
    {_, {_pending, pairs}} =
      Macro.prewalk(ast, {nil, []}, fn
        {:@, _, [{:doc, meta, [docstring]}]} = node, {_pending, pairs}
        when is_binary(docstring) ->
          {node, {{docstring, meta}, pairs}}

        {:def, _, [{name, _, _} | _]} = node, {{docstring, meta}, pairs} when is_atom(name) ->
          {node, {nil, [{docstring, meta, name} | pairs]}}

        {:def, _, _} = node, {_pending, pairs} ->
          {node, {nil, pairs}}

        {:defp, _, _} = node, {_pending, pairs} ->
          {node, {nil, pairs}}

        {:@, _, [{attr, _, _}]} = node, {_pending, pairs} when attr in [:doc, :moduledoc] ->
          {node, {nil, pairs}}

        node, acc ->
          {node, acc}
      end)

    pairs
  end

  defp restates_name?(docstring, fun_name) do
    trimmed = String.trim(docstring)

    single_sentence?(trimmed) and words_from_name_in_doc?(trimmed, fun_name)
  end

  defp single_sentence?(doc) do
    not String.contains?(doc, "\n") and String.length(doc) < 80
  end

  defp words_from_name_in_doc?(doc, fun_name) do
    name_words =
      fun_name
      |> Atom.to_string()
      |> String.split("_")
      |> Enum.reject(&(&1 in ~w(a an the is do)))

    doc_lower = doc |> String.downcase() |> String.replace(~r/[^a-z\s]/, "")

    length(name_words) >= 2 and
      Enum.all?(name_words, fn word ->
        String.contains?(doc_lower, word)
      end)
  end

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message: "`@doc` restates the function name — explain constraints/behavior or remove it.",
      trigger: "@doc",
      line_no: meta[:line]
    )
  end
end
