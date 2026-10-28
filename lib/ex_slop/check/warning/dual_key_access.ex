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

          # bad — same thing with a variable key converted between forms
          Map.get(data, key) || Map.get(data, Atom.to_string(key))
          data[key] || data[String.to_atom(key)]

          # bad — one function with clauses for both key forms
          defp detail_value(%{"from" => from, "to" => to}), do: {from, to}
          defp detail_value(%{from: from, to: to}), do: {from, to}

          # good — normalize once at the boundary, then use one key type
          Map.get(usage, :input_tokens, 0)

      Function clauses are compared per argument position, using only literal
      keys of plain map patterns. Struct patterns are not compared.
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

  defp walk({:__block__, _meta, statements} = ast, ctx) do
    ctx =
      statements
      |> Enum.flat_map(&function_clause/1)
      |> Enum.chunk_by(fn {function, _meta, _params} -> function end)
      |> Enum.filter(&dual_key_clauses?/1)
      |> Enum.reduce(ctx, fn [{_function, meta, _params} | _], ctx ->
        put_issue(ctx, issue_for(ctx, meta))
      end)

    {ast, ctx}
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

  defp keyed_access(map, key) do
    case variable_key(key) do
      nil -> nil
      {name, form} -> {Macro.to_string(map), {:variable, name}, form}
    end
  end

  defp variable_key({{:., _, [{:__aliases__, _, [:Atom]}, :to_string]}, _, [variable]}),
    do: converted(variable)

  defp variable_key({{:., _, [{:__aliases__, _, [:String]}, fun]}, _, [variable]})
       when fun in [:to_atom, :to_existing_atom],
       do: converted(variable)

  defp variable_key({:to_string, _, [variable]}), do: converted(variable)

  defp variable_key({name, _, context}) when is_atom(name) and is_atom(context),
    do: {name, :bare}

  defp variable_key(_key), do: nil

  defp converted({name, _, context}) when is_atom(name) and is_atom(context),
    do: {name, :converted}

  defp converted(_ast), do: nil

  # Literal keys are typed :atom or :string, variable keys :bare or :converted.
  # Either way, two different types for the same map and key is the smell.
  defp dual_key_access?(accesses) do
    accesses
    |> Enum.group_by(fn {map, key, _type} -> {map, key} end, fn {_map, _key, type} -> type end)
    |> Enum.any?(fn {_field, types} -> match?([_, _ | _], Enum.uniq(types)) end)
  end

  defp function_clause({kind, meta, [head | _]}) when kind in [:def, :defp] do
    case function_head(head) do
      {name, params} -> [{{kind, name, length(params)}, meta, params}]
      nil -> []
    end
  end

  defp function_clause(_ast), do: []

  defp function_head({:when, _, [head | _]}), do: function_head(head)

  defp function_head({name, _, params}) when is_atom(name) and is_list(params),
    do: {name, params}

  defp function_head(_head), do: nil

  defp dual_key_clauses?([_, _ | _] = clauses) do
    clauses
    |> Enum.map(fn {_function, _meta, params} -> params end)
    |> Enum.zip_with(& &1)
    |> Enum.any?(fn patterns -> patterns |> Enum.map(&pattern_keys/1) |> mixed_key_forms?() end)
  end

  defp dual_key_clauses?(_clauses), do: false

  # True when one clause matches a key as an atom and another clause matches
  # the same key as a string.
  defp mixed_key_forms?(clause_keys) do
    indexed = Enum.with_index(clause_keys)

    Enum.any?(indexed, fn {{atoms, _strings}, index} ->
      Enum.any?(indexed, fn {{_atoms, strings}, other_index} ->
        index != other_index and not MapSet.disjoint?(atoms, strings)
      end)
    end)
  end

  defp pattern_keys({:\\, _, [pattern, _default]}), do: pattern_keys(pattern)

  defp pattern_keys({:=, _, [left, right]}) do
    {left_atoms, left_strings} = pattern_keys(left)
    {right_atoms, right_strings} = pattern_keys(right)
    {MapSet.union(left_atoms, right_atoms), MapSet.union(left_strings, right_strings)}
  end

  defp pattern_keys({:%{}, _, pairs}) do
    keys = for {key, _value} <- pairs, do: key

    {MapSet.new(for key <- keys, is_atom(key), do: Atom.to_string(key)),
     MapSet.new(for key <- keys, is_binary(key), do: key)}
  end

  defp pattern_keys(_pattern), do: {MapSet.new(), MapSet.new()}

  defp issue_for(ctx, meta) do
    format_issue(ctx,
      message:
        "Dual atom/string key access — normalize the map once instead of checking both key types.",
      trigger: "dual key access",
      line_no: meta[:line]
    )
  end
end
