defmodule ExSlop do
  @moduledoc """
  Credo checks that catch AI-generated code slop in Elixir.

  Add checks to `.credo.exs` — see `README.md` for the full list.
  """

  @checks [
    ExSlop.Check.Warning.BlanketRescue,
    ExSlop.Check.Warning.RescueWithoutReraise,
    ExSlop.Check.Warning.RepoAllThenFilter,
    ExSlop.Check.Warning.QueryInEnumMap,
    ExSlop.Check.Warning.GenserverAsKvStore,
    ExSlop.Check.Refactor.FilterNil,
    ExSlop.Check.Refactor.ReduceAsMap,
    ExSlop.Check.Refactor.MapIntoLiteral,
    ExSlop.Check.Refactor.IdentityPassthrough,
    ExSlop.Check.Refactor.IdentityMap,
    ExSlop.Check.Refactor.CaseTrueFalse,
    ExSlop.Check.Refactor.TryRescueWithSafeAlternative,
    ExSlop.Check.Refactor.WithIdentityElse,
    ExSlop.Check.Readability.NarratorDoc,
    ExSlop.Check.Readability.DocFalseOnPublicFunction,
    ExSlop.Check.Readability.BoilerplateDocParams,
    ExSlop.Check.Readability.ObviousComment,
    ExSlop.Check.Readability.StepComment
  ]

  def checks, do: @checks
end
