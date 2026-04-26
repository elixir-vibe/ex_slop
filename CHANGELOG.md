# Changelog

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
