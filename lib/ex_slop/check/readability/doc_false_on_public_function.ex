defmodule ExSlop.Check.Readability.DocFalseOnPublicFunction do
  use Credo.Check,
    id: "EXS3005",
    base_priority: :low,
    category: :readability,
    tags: [:ex_slop],
    explanations: [
      check: """
      `@doc false` on a public function (`def`, not `defp`) is a code smell.
      If the function is truly internal, make it `defp`. If it's public API,
      document it.

      This check skips known legitimate uses:
      - Functions annotated with `@impl true` (behaviour callbacks)
      - OTP callbacks: `child_spec`, `start_link`, `init`
      - Protocol/macro internals: `__using__`, `__changeset__`, etc.

          # bad — cargo-culted from Phoenix generators
          @doc false
          def changeset(user, attrs) do

          # good — either document it
          @doc "Casts and validates registration fields."
          def changeset(user, attrs) do

          # good — or make it private
          defp changeset(user, attrs) do
      """
    ]

  @otp_callbacks ~w(child_spec start_link init terminate code_change
    handle_call handle_cast handle_info handle_continue format_status)a

  @dunder_functions ~w(__using__ __before_compile__ __after_compile__
    __changeset__ __struct__ __schema__ __fields__ __resource__)a

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:@, _, [{:doc, _, [false]}]} = ast, ctx) do
    {ast, Map.put(ctx, :doc_false_line, source_line(ast))}
  end

  defp walk({:@, _, [{:impl, _, [true]}]} = ast, ctx) do
    {ast, Map.delete(ctx, :doc_false_line)}
  end

  defp walk({:@, _, [{:impl, _, [{:__block__, _, [true]}]}]} = ast, ctx) do
    {ast, Map.delete(ctx, :doc_false_line)}
  end

  defp walk({:def, meta, [{name, _, _} | _]} = ast, ctx) when is_atom(name) do
    if Map.has_key?(ctx, :doc_false_line) do
      ctx = Map.delete(ctx, :doc_false_line)

      if exempt?(name) do
        {ast, ctx}
      else
        {ast, put_issue(ctx, issue_for(ctx, meta, name))}
      end
    else
      {ast, ctx}
    end
  end

  defp walk({:defp, _, _} = ast, ctx) do
    {ast, Map.delete(ctx, :doc_false_line)}
  end

  defp walk({:@, _, [{attr, _, _}]} = ast, ctx) when attr in [:doc, :moduledoc] do
    {ast, Map.delete(ctx, :doc_false_line)}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp exempt?(name) do
    name in @otp_callbacks or name in @dunder_functions
  end

  defp source_line({:@, meta, _}), do: meta[:line]
  defp source_line(_), do: nil

  defp issue_for(ctx, meta, name) do
    format_issue(ctx,
      message: "`@doc false` on public `def #{name}` — document it or make it `defp`.",
      trigger: "@doc false",
      line_no: meta[:line]
    )
  end
end
