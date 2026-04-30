# ExSlop Agent Guidelines

This repository is part of the Elixir Vibe organization.

ExSlop provides Credo checks for AI-generated Elixir code slop.

## Development

Use the project’s Mix aliases whenever possible.

```sh
mix deps.get
mix compile
mix test
mix format
```

Preferred full check:

```sh
mix ci
```

Current full CI alias includes:

```sh
mix compile --warnings-as-errors
mix format --check-formatted
mix test
mix credo --strict
mix dialyzer
mix ex_dna
mix dogfood
```

## Guidelines

- Checks should minimize false positives.
- Prefer precise, explainable warnings.
- Every new check needs tests with both positive and negative examples.
- Dogfooding is part of the project identity; do not remove it casually.
- Do not flag idiomatic Elixir just because it looks unusual.
- Do not publish, tag, or bump versions unless explicitly requested.
