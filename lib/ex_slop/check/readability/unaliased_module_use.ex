defmodule ExSlop.Check.Readability.UnaliasedModuleUse do
  use Credo.Check,
    id: "EXS3009",
    base_priority: :low,
    category: :readability,
    tags: [:ex_slop],
    param_defaults: [min_count: 3],
    explanations: [
      check: """
      LLMs tend to paste the same fully-qualified module name into every
      call inside a function body. A single `Credo.Code.prewalk` is fine;
      five of them in one function is unreadable slop.

      Unlike Credo's `AliasUsage` (which flags every nested call and
      excludes ~50 stdlib lastnames by default), this check only fires
      when a module is used repeatedly *within a single function body*.

          # bad — AI slop (3+ uses in one function)
          def run(source_file) do
            Credo.Code.prewalk(source_file, &walk/2, ctx)
            Credo.Code.remove_metadata(pattern)
            Credo.Code.remove_metadata(body)
          end

          # good
          def run(source_file) do
            alias Credo.Code
            Code.prewalk(source_file, &walk/2, ctx)
            Code.remove_metadata(pattern)
            Code.remove_metadata(body)
          end

          # fine — only one use, no alias needed
          def run(source_file) do
            Credo.Code.prewalk(source_file, &walk/2, ctx)
          end
      """,
      params: [
        min_count: "Minimum uses of a module within a single function body (default: 3)."
      ]
    ]

  alias Credo.Code.Name

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    min_count = Params.get(params, :min_count, __MODULE__)
    ctx = Context.build(source_file, params, __MODULE__)

    ast = SourceFile.ast(source_file)
    aliases = collect_aliases(ast)

    find_dense_uses(ast, aliases, min_count)
    |> Enum.reduce(ctx, fn {trigger, line_no, count}, ctx ->
      put_issue(
        ctx,
        format_issue(ctx,
          message: "Fully-qualified `#{trigger}` used #{count}× in function — add an `alias`.",
          trigger: trigger,
          line_no: line_no
        )
      )
    end)
    |> Map.get(:issues, [])
  end

  defp collect_aliases(ast) do
    {_, %{full: full, local: local}} =
      Macro.prewalk(ast, %{full: MapSet.new(), local: MapSet.new()}, fn
        {:alias, _, [{:__aliases__, _, parts}, [as: {:__aliases__, _, local_parts}]]} = node,
        acc ->
          {node,
           %{
             acc
             | full: MapSet.put(acc.full, Name.full(parts)),
               local: MapSet.put(acc.local, Name.full(local_parts))
           }}

        {:alias, _, [{:__aliases__, _, parts} | _]} = node, acc ->
          full_name = Name.full(parts)
          last_name = Name.last(parts)

          {node,
           %{
             acc
             | full: MapSet.put(acc.full, full_name),
               local: MapSet.put(acc.local, last_name)
           }}

        node, acc ->
          {node, acc}
      end)

    %{full: full, local: local}
  end

  defp find_dense_uses(ast, aliases, min_count) do
    {_, issues} =
      Macro.prewalk(ast, [], fn
        {op, _, _} = node, acc when op in [:def, :defp] ->
          {node, collect_fqns_from_fun(node, acc, aliases, min_count)}

        node, acc ->
          {node, acc}
      end)

    issues
  end

  defp collect_fqns_from_fun(node, acc, aliases, min_count) do
    {_, fun_counts} =
      Macro.prewalk(node, %{}, &count_fqns_in_body(&1, &2, aliases))

    fun_issues =
      fun_counts
      |> Enum.filter(fn {_trigger, %{count: count}} -> count >= min_count end)
      |> Enum.map(fn {trigger, %{line_no: line_no, count: count}} ->
        {trigger, line_no, count}
      end)

    fun_issues ++ acc
  end

  defp count_fqns_in_body({:@, _, _}, acc, _aliases) do
    {nil, acc}
  end

  defp count_fqns_in_body({:alias, _, _}, acc, _aliases) do
    {nil, acc}
  end

  defp count_fqns_in_body(
         {:., meta, [{:__aliases__, _, mod_list}, fun_atom]} = ast,
         acc,
         aliases
       )
       when is_list(mod_list) and is_atom(fun_atom) do
    if short_module?(mod_list) or should_skip?(mod_list, aliases) do
      {ast, acc}
    else
      trigger = Name.full(mod_list)

      acc =
        Map.update(acc, trigger, %{count: 1, line_no: meta[:line]}, fn existing ->
          %{existing | count: existing.count + 1}
        end)

      {ast, acc}
    end
  end

  defp count_fqns_in_body(ast, acc, _aliases) do
    {ast, acc}
  end

  defp short_module?([_, _ | _]), do: false
  defp short_module?(_), do: true

  defp should_skip?(mod_list, %{full: full, local: local}) do
    full_name = Name.full(mod_list)

    cond do
      Enum.any?(mod_list, &unquote?/1) -> true
      full_name in full -> true
      locally_aliased?(mod_list, local) -> true
      true -> false
    end
  end

  defp locally_aliased?([top | _], local), do: Name.full([top]) in local
  defp locally_aliased?(_, _local), do: false

  defp unquote?({:unquote, _, _}), do: true
  defp unquote?(_), do: false
end
