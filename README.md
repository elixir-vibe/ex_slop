# ExSlop

[![Hex.pm](https://img.shields.io/hexpm/v/ex_slop.svg)](https://hex.pm/packages/ex_slop)

Credo checks that catch AI-generated code slop in Elixir.

23 checks for patterns that LLMs produce but experienced Elixir developers
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
{ExSlop.Check.Readability.NarratorDoc, []},
{ExSlop.Check.Readability.DocFalseOnPublicFunction, []},
{ExSlop.Check.Readability.BoilerplateDocParams, []},
{ExSlop.Check.Readability.ObviousComment, [additional_keywords: []]},
{ExSlop.Check.Readability.StepComment, []},
{ExSlop.Check.Readability.NarratorComment, []}
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

### Readability

| Check | What it catches |
|-------|-----------------|
| `NarratorDoc` | `@moduledoc "This module provides functionality for..."` |
| `DocFalseOnPublicFunction` | Multiple `@doc false` on `def` in one module — cargo-culted |
| `BoilerplateDocParams` | `## Parameters\n- conn: The connection struct` |
| `ObviousComment` | `# Fetch the user` above `Repo.get(User, id)` |
| `StepComment` | `# Step 1: Validate input` |
| `NarratorComment` | `# Here we fetch the user` / `# Now we validate` / `# Let's create` |

## License

[MIT](LICENSE)
