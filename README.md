# ExSlop

Credo checks that catch AI-generated code slop in Elixir.

Detects patterns that LLMs produce but experienced Elixir developers don't:
blanket rescues, narrator docs, obvious comments, anti-idiomatic Enum usage,
try/rescue around non-raising functions, N+1 queries, and more.

18 checks. None overlap with built-in Credo.

## Installation

```elixir
def deps do
  [{:ex_slop, "~> 0.1", only: [:dev, :test], runtime: false}]
end
```

Add checks to `.credo.exs`:

```elixir
%{
  configs: [
    %{
      name: "default",
      checks: %{
        enabled: [
          # ... existing checks ...

          # ExSlop
          {ExSlop.Check.Warning.BlanketRescue, []},
          {ExSlop.Check.Warning.RescueWithoutReraise, []},
          {ExSlop.Check.Warning.RepoAllThenFilter, []},
          {ExSlop.Check.Warning.QueryInEnumMap, []},
          {ExSlop.Check.Warning.GenserverAsKvStore, []},
          {ExSlop.Check.Refactor.FilterNil, []},
          {ExSlop.Check.Refactor.ReduceAsMap, []},
          {ExSlop.Check.Refactor.MapIntoLiteral, []},
          {ExSlop.Check.Refactor.IdentityPassthrough, []},
          {ExSlop.Check.Refactor.IdentityMap, []},
          {ExSlop.Check.Refactor.CaseTrueFalse, []},
          {ExSlop.Check.Refactor.TryRescueWithSafeAlternative, []},
          {ExSlop.Check.Refactor.WithIdentityElse, []},
          {ExSlop.Check.Readability.NarratorDoc, []},
          {ExSlop.Check.Readability.DocFalseOnPublicFunction, []},
          {ExSlop.Check.Readability.BoilerplateDocParams, []},
          {ExSlop.Check.Readability.ObviousComment, []},
          {ExSlop.Check.Readability.StepComment, []},
        ]
      }
    }
  ]
}
```

## What it catches

### Warnings

| Check | Example |
|-------|---------|
| `BlanketRescue` | `rescue _ -> nil` or `rescue _e -> {:error, "..."}` |
| `RescueWithoutReraise` | `rescue e -> Logger.error(...); :error` |
| `RepoAllThenFilter` | `Repo.all(User) \|> Enum.filter(& &1.active)` |
| `QueryInEnumMap` | `Enum.map(users, fn u -> Repo.all(...) end)` — N+1 |
| `GenserverAsKvStore` | `handle_call({:get, key}, ...) -> Map.get(state, key)` |

### Refactoring

| Check | Bad | Good |
|-------|-----|------|
| `FilterNil` | `Enum.filter(fn x -> x != nil end)` | `Enum.reject(&is_nil/1)` |
| `ReduceAsMap` | `Enum.reduce([], fn x, acc -> [f(x) \| acc] end)` | `Enum.map(&f/1)` |
| `MapIntoLiteral` | `Enum.map(...) \|> Enum.into(%{})` | `Map.new(...)` |
| `IdentityPassthrough` | `case r do {:ok, v} -> {:ok, v}; ... end` | `r` |
| `IdentityMap` | `Enum.map(fn x -> x end)` | remove the call |
| `CaseTrueFalse` | `case flag do true -> a; false -> b end` | `if flag, do: a, else: b` |
| `TryRescueWithSafeAlternative` | `try do String.to_integer(x) rescue _ end` | `Integer.parse(x)` |
| `WithIdentityElse` | `with ... else {:error, r} -> {:error, r} end` | remove the `else` |

### Readability

| Check | Example |
|-------|---------|
| `NarratorDoc` | `@moduledoc "This module provides functionality for..."` |
| `DocFalseOnPublicFunction` | `@doc false` on `def` (not `defp`) |
| `BoilerplateDocParams` | `## Parameters\n- conn: The connection struct` |
| `ObviousComment` | `# Fetch the user` above `Repo.get(User, id)` |
| `StepComment` | `# Step 1: Validate input` |

## Why not Credo?

Credo covers ~100 checks. None of these 18 patterns are covered:

- Credo never inspects comment or doc **content** — only presence
- Blanket `rescue _ -> nil` is unchecked
- `Enum.filter(fn x -> x != nil end)` is not detected
- `try/rescue` around `String.to_integer` vs `Integer.parse` — not detected
- Ecto anti-patterns (`Repo.all |> Enum.filter`, N+1) — out of scope for Credo
- `Enum.map |> Enum.into(%{})` — Credo's `MapInto` is disabled for Elixir ≥ 1.8
- Identity `case` passthrough — Credo's `CaseTrivialMatches` is deprecated

## License

[MIT](LICENSE)
