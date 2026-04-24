# ExSlop

[![Hex.pm](https://img.shields.io/hexpm/v/ex_slop.svg)](https://hex.pm/packages/ex_slop)

Credo checks that catch AI-generated code slop in Elixir.

29 checks for patterns that LLMs produce but experienced Elixir developers
don't — blanket rescues, narrator docs, obvious comments, anti-idiomatic
Enum usage, try/rescue around non-raising functions, N+1 queries, and more.

None of these overlap with built-in Credo: Credo never inspects doc/comment
**content**, doesn't catch Ecto anti-patterns or identity passthrough, and its
`MapInto` / `CaseTrivialMatches` checks are disabled or deprecated.

## Installation

Add to `mix.exs`:

```elixir
def deps do
  [
    {:ex_slop, "~> 0.1", only: [:dev, :test], runtime: false}
  ]
end
```

Then add the checks you want to your `.credo.exs` — just append to the
existing `enabled` list:

```elixir
# .credo.exs
{ExSlop.Check.Warning.BlanketRescue, []},
{ExSlop.Check.Warning.RescueWithoutReraise, []},
{ExSlop.Check.Warning.RepoAllThenFilter, []},
{ExSlop.Check.Warning.QueryInEnumMap, []},
{ExSlop.Check.Warning.GenserverAsKvStore, []},
{ExSlop.Check.Warning.PathExpandPriv, []},
{ExSlop.Check.Warning.DualKeyAccess, []},

{ExSlop.Check.Refactor.FilterNil, []},
{ExSlop.Check.Refactor.RejectNil, []},
{ExSlop.Check.Refactor.ReduceAsMap, []},
{ExSlop.Check.Refactor.MapIntoLiteral, []},
{ExSlop.Check.Refactor.IdentityPassthrough, []},
{ExSlop.Check.Refactor.IdentityMap, []},
{ExSlop.Check.Refactor.CaseTrueFalse, []},
{ExSlop.Check.Refactor.TryRescueWithSafeAlternative, []},
{ExSlop.Check.Refactor.WithIdentityElse, []},
{ExSlop.Check.Refactor.WithIdentityDo, []},
{ExSlop.Check.Refactor.SortThenReverse, []},
{ExSlop.Check.Refactor.StringConcatInReduce, []},
{ExSlop.Check.Refactor.ReduceMapPut, []},
{ExSlop.Check.Refactor.RedundantBooleanIf, []},
{ExSlop.Check.Refactor.FlatMapFilter, []},
{ExSlop.Check.Readability.NarratorDoc, []},
{ExSlop.Check.Readability.DocFalseOnPublicFunction, []},
{ExSlop.Check.Readability.BoilerplateDocParams, []},
{ExSlop.Check.Readability.ObviousComment, [additional_keywords: []]},
{ExSlop.Check.Readability.StepComment, []},
{ExSlop.Check.Readability.NarratorComment, []},
{ExSlop.Check.Readability.UnaliasedModuleUse, []}
```

Cherry-pick only the checks that make sense for your project.

## Checks

### Warnings

| Check | What it catches |
|-------|-----------------|
| `BlanketRescue` | `rescue _ -> nil` or `rescue _e -> {:error, "..."}` |
| `RescueWithoutReraise` | `rescue e -> Logger.error(...); :error` — logs but swallows |
| `RepoAllThenFilter` | `Repo.all(User) \|> Enum.filter(& &1.active)` — filter in SQL |
| `QueryInEnumMap` | `Enum.map(users, fn u -> Repo.get(...) end)` — N+1 query |
| `GenserverAsKvStore` | GenServer that's just `Map.get`/`Map.put` on state — use ETS or Agent |
| `PathExpandPriv` | `Path.expand("...priv...", __DIR__)` — use `Application.app_dir/2` |
| `DualKeyAccess` | `Map.get(m, :key) \|\| Map.get(m, "key")` — normalize once instead |

### Refactoring

| Check | Bad | Good |
|-------|-----|------|
| `FilterNil` | `Enum.filter(fn x -> x != nil end)` | `Enum.reject(&is_nil/1)` |
| `RejectNil` | `Enum.reject(fn x -> x == nil end)` | `Enum.reject(&is_nil/1)` |
| `ReduceAsMap` | `Enum.reduce([], fn x, acc -> [f(x) \| acc] end)` | `Enum.map(&f/1)` |
| `MapIntoLiteral` | `Enum.map(...) \|> Enum.into(%{})` | `Map.new(...)` |
| `IdentityPassthrough` | `case r do {:ok, v} -> {:ok, v}; {:error, e} -> {:error, e} end` | `r` |
| `IdentityMap` | `Enum.map(fn x -> x end)` | remove the call |
| `CaseTrueFalse` | `case flag do true -> a; false -> b end` | `if flag, do: a, else: b` |
| `TryRescueWithSafeAlternative` | `try do String.to_integer(x) rescue _ -> nil end` | `Integer.parse(x)` |
| `WithIdentityElse` | `with {:ok, v} <- f() do v else {:error, r} -> {:error, r} end` | drop the `else` |
| `WithIdentityDo` | `with {:ok, v} <- f() do {:ok, v} end` | `f()` |
| `SortThenReverse` | `Enum.sort() \|> Enum.reverse()` | `Enum.sort(:desc)` |
| `StringConcatInReduce` | `Enum.reduce("", fn x, acc -> acc <> x end)` | `Enum.join/1` or IO data |
| `ReduceMapPut` | `Enum.reduce(%{}, fn x, acc -> Map.put(acc, k, v) end)` | `Map.new/2` |
| `RedundantBooleanIf` | `if cond, do: true, else: false` | use the condition directly |
| `FlatMapFilter` | `Enum.flat_map(fn x -> if cond, do: [x], else: [] end)` | `Enum.filter/2` |

### Readability

| Check | What it catches |
|-------|-----------------|
| `NarratorDoc` | `@moduledoc "This module provides functionality for..."` |
| `DocFalseOnPublicFunction` | Multiple `@doc false` on `def` in one module — cargo-culted |
| `BoilerplateDocParams` | `## Parameters\n- conn: The connection struct` |
| `ObviousComment` | `# Fetch the user` above `Repo.get(User, id)` |
| `StepComment` | `# Step 1: Validate input` |
| `NarratorComment` | `# Here we fetch the user` / `# Now we validate` / `# Let's create` |
| `UnaliasedModuleUse` | `Credo.Code.prewalk` used 2+ times without `alias Credo.Code` |

## Recommended Credo Built-in Checks

These Credo built-in checks are especially good at catching AI slop.
Enable them in your `.credo.exs` if you haven't already:

```elixir
# Catches length(list) == 0 (traverses entire list) → use list == [] or Enum.empty?/1
{Credo.Check.Warning.ExpensiveEmptyEnumCheck, []},

# Catches Enum.map(...) |> Enum.join(...) → Enum.map_join(...)
{Credo.Check.Refactor.MapJoin, []},

# Catches acc ++ [item] (O(n²) append) → use [item | acc] then Enum.reverse
{Credo.Check.Refactor.AppendSingleItem, []},

# Catches !!var (double negation) — LLMs use this to "cast to boolean"
{Credo.Check.Refactor.DoubleBooleanNegation, []},

# Catches case x do true -> a; false -> b end → if/else
{Credo.Check.Refactor.CondStatements, []},

# Catches Enum.map |> Enum.map → single Enum.map
{Credo.Check.Refactor.MapMap, []},

# Catches Enum.filter |> Enum.filter → single Enum.filter
{Credo.Check.Refactor.FilterFilter, []},

# Catches Enum.reject |> Enum.reject → single Enum.reject
{Credo.Check.Refactor.RejectReject, []},

# Catches Enum.count(enum) > 0 → Enum.any?/1
{Credo.Check.Refactor.FilterCount, []},

# Catches negated conditions in unless → rewrite with positive condition
{Credo.Check.Refactor.NegatedConditionsInUnless, []},

# Catches unless x do .. else .. end → if/else (clearer)
{Credo.Check.Refactor.UnlessWithElse, []}
```

## License

[MIT](LICENSE)
