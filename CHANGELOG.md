# Changelog

## Unreleased

### Fixed

- `IdentityPassthrough` no longer flags map/struct projections (`%{a: a} -> %{a: a}` drops extra keys). A non-exhaustive identity `case` is still reported, but the message now notes that it raises `CaseClauseError` on unmatched values whereas returning the value directly does not.
- `ReduceMapPut` no longer flags reductions whose key or value reads the accumulator (e.g. summing duplicate keys), since `Map.new/2` cannot express them.
- `PreferEnumSlice` no longer flags `Enum.drop/2 |> Enum.take/2` with negative literal arguments, which `Enum.slice/3` does not treat the same way.
- `FlatMapFilter` now only flags callbacks whose singleton list holds the argument unchanged; `[x * 2]` is a transformation that `Enum.filter/2` cannot replace.
- `IdentityMap` now suggests `Enum.to_list/1` for inputs that may not be lists (ranges, streams, `MapSet`s), since removing the call would change the return type.
- `SortThenReverse` no longer flags `Enum.sort_by/2 |> Enum.reverse/1`: sorting is stable, so the reverse changes the relative order of equal keys while `Enum.sort_by(fun, :desc)` preserves it.

## 0.4.4 - 2026-07-25

### Added

- Warn when ExSlop is registered as a plugin but none of its checks are active, typically because an explicit `checks.enabled` list overrides the plugin defaults. The warning and README explain how to append `ExSlop.recommended_checks/0` to the enabled checks.

## 0.4.3

### Changed

- Lowered the declared minimum Elixir version from 1.19 to 1.18.

### Fixed

- Made the Credo plugin interface test reliable in clean, isolated builds.

## 0.4.2

### Added

- Added **`LengthComparison`** (`EXS4027`) — flags `length/1` compared against an integer literal (`==`, `!=`, `>`, `<`, `>=`, `<=`) in any context, guard or body. Complements `LengthInGuard`, which only covers guards: moving the comparison into an `if` no longer hides it. Use pattern matching (`[]`, `[_ | _]`) or `Enum.count_until/2` for a threshold.

## 0.4.0

### Added

- Added **`ExSlop` recommended bundle** — configure `{ExSlop, :recommended}` to enable the curated high-signal check set.
- Added **`ExSlop.recommended_checks/0`** for tools that want the same curated check list programmatically.
- Added **`RedundantEnumJoinSeparator`** (`EXS4016`) — flags `Enum.join(parts, "")`; use `Enum.join(parts)` instead.
- Added **`UseMapJoin`** (`EXS4017`) — flags `Enum.map/2 |> Enum.join/1`; use `Enum.map_join/3` instead. Opt-in only.
- Added **`PreferEnumSlice`** (`EXS4018`) — flags `Enum.drop/2 |> Enum.take/2`; use `Enum.slice/3` instead. Opt-in only.
- Added **`GraphemesLength`** (`EXS4019`) — flags counting `String.graphemes/1`; use `String.length/1` instead.
- Added **`ManualStringReverse`** (`EXS4020`) — flags `String.graphemes/1 |> Enum.reverse/1 |> Enum.join/1`; use `String.reverse/1` instead.
- Added **`SortThenAt`** (`EXS4021`) — flags `Enum.sort/1 |> Enum.at/2` when a single-pass selection is likely clearer.
- Added **`SortForTopK`** (`EXS4022`) — flags `Enum.sort/1 |> Enum.take(1)` and `Enum.sort/1 |> hd/1`; use min/max or single-pass selection instead.
- Added **`ListFold`** (`EXS4023`) — flags `List.foldl/3` and `List.foldr/3`; use `Enum.reduce/3` instead. Opt-in only.
- Added **`ListLast`** (`EXS4024`) — flags `List.last/1` because it traverses the whole list. Opt-in only.
- Added **`LengthInGuard`** (`EXS4025`) — flags `length/1` in guards; prefer pattern matching where possible. Opt-in only.
- Added **`ExplicitSumReduce`** (`EXS4026`) — flags manual summing with `Enum.reduce/3`; use `Enum.sum/1` instead.

### Changed

- The recommended bundle now excludes checks that proved noisy on mature Elixir codebases, while keeping them available for explicit opt-in.
- Updated documentation with the recommended bundle and full check list.

## 0.3.1

### New checks

- **`PathExpandPriv`** (`EXS1006`) — flags `Path.expand("...priv...", __DIR__)` for application resources; use `Application.app_dir/2` instead.
- **`DualKeyAccess`** (`EXS1007`) — flags mixed atom/string key access; normalize data once at the boundary instead.
- **`ReduceMapPut`** (`EXS4013`) — flags `Enum.reduce(%{}, fn x, acc -> Map.put(acc, key, value) end)`; use `Map.new/2` instead.
- **`RedundantBooleanIf`** (`EXS4014`) — flags `if condition, do: true, else: false`; use the condition directly.
- **`FlatMapFilter`** (`EXS4015`) — flags `Enum.flat_map(fn x -> if condition, do: [x], else: [] end)`; use `Enum.filter/2` instead.

### Fixes

- Improved `DualKeyAccess` to catch mixed atom/string access across `Map.get`, `Map.fetch`, `Map.fetch!`, `get_in`, access syntax, and chained `||` expressions.
- Fixed `BlanketRescue` false positives for specific exception rescues.

## 0.3.0

### New check

- **`UnaliasedModuleUse`** (`EXS3009`) — flags when a fully-qualified module name (e.g. `Credo.Code.prewalk`) is used 3+ times within a single function body without an `alias`. Unlike Credo's built-in `AliasUsage`, this check has no stdlib exclusion list and only fires on dense per-function repetition, which is the hallmark AI slop pattern.

### Fixes

- Replaced all `~r//` regex literals with string operations or `Regex.compile!` to eliminate dialyzer false positives.
- Added missing `alias` declarations in existing checks that were triggering the new `UnaliasedModuleUse` check during dogfooding.

## 0.2.0

### New checks

- `BoilerplateDocParams` — flags `## Parameters` docs that restate the function signature.
- `DocFalseOnPublicFunction` — flags multiple `@doc false` on `def` in the same module.
- `NarratorComment` — flags "Here we..." / "Let's..." style comments.
- `NarratorDoc` — flags "This module provides..." style docs.
- `StepComment` — flags "Step 1: ..." comments.

### Changes

- `ObviousComment` and `NarratorComment` tightened to reduce false positives.

## 0.1.1

- `DocFalseOnPublicFunction` now only flags when 2+ occurrences exist in the same module.

## 0.1.0

- Initial release with 14 checks.
