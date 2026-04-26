defmodule ExSlop.Check.Warning.DualKeyAccess do
  use Credo.Check,
    id: "EXS1007",
    base_priority: :normal,
    category: :warning,
    tags: [:ex_slop],
    explanations: [
      check: """
      Checking both atom and string keys for the same field means the data shape
      is unknown. This is usually defensive coding where a boundary should
      normalize the map once.

          # bad — doesn't know if keys are atoms or strings
          Map.get(usage, :input_tokens) || Map.get(usage, "input_tokens") || 0
          get_in(data, [:path]) || get_in(data, ["path"])
          payload[:kind] || payload["kind"]

          # good — normalize once at the boundary, then use one key type
          Map.get(usage, :input_tokens, 0)
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    Enum.uniq_by(result.issues, &{&1.filename, &1.line_no, &1.scope})
  end

  defp walk({:||, meta, _args} = ast, ctx) do
    accesses = ast |> operands() |> Enum.flat_map(&accesses/1)

    if dual_key_access?(accesses) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp operands({:||, _, [left, right]}), do: operands(left) ++ operands(right)
  defp operands(ast), do: [ast]

  defp accesses(ast) do
    case access(ast) do
      nil -> []
      access -> [access]
    end
  end

  defp access({{:., _, [{:__aliases__, _, [:Map]}, fun]}, _, [map, key | _]})
       when fun in [:get, :fetch, :fetch!] do
    keyed_access(map, key)
  end

  defp access({{:., _, [Access, :get]}, _, [map, key | _]}) do
    keyed_access(map, key)
  end

  defp access({:get_in, _, [map, [key]]}) do
    keyed_access(map, key)
  end

  defp access(_ast), do: nil

  defp keyed_access(map, key) when is_atom(key),
    do: {Macro.to_string(map), Atom.to_string(key), :atom}

  defp keyed_access(map, key) when is_binary(key), do: {Macro.to_string(map), key, :string}
  defp keyed_access(_map, _key), do: nil

  defp dual_key_access?(accesses) do
    accesses
    |> Enum.group_by(fn {map, key, _type} -> {map, key} end, fn {_map, _key, type} -> type end)
    |> Enum.any?(fn {_field, types} -> :atom in types and :string in types end)
  end

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "Dual atom/string key access — normalize the map once instead of checking both key types.",
      trigger: "dual key access",
      line_no: meta[:line]
    )
  end
end
