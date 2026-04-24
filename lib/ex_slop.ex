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
    ExSlop.Check.Warning.PathExpandPriv,
    ExSlop.Check.Warning.DualKeyAccess,
    ExSlop.Check.Refactor.FilterNil,
    ExSlop.Check.Refactor.RejectNil,
    ExSlop.Check.Refactor.ReduceAsMap,
    ExSlop.Check.Refactor.MapIntoLiteral,
    ExSlop.Check.Refactor.IdentityPassthrough,
    ExSlop.Check.Refactor.IdentityMap,
    ExSlop.Check.Refactor.CaseTrueFalse,
    ExSlop.Check.Refactor.TryRescueWithSafeAlternative,
    ExSlop.Check.Refactor.WithIdentityElse,
    ExSlop.Check.Refactor.WithIdentityDo,
    ExSlop.Check.Refactor.SortThenReverse,
    ExSlop.Check.Refactor.StringConcatInReduce,
    ExSlop.Check.Refactor.ReduceMapPut,
    ExSlop.Check.Refactor.RedundantBooleanIf,
    ExSlop.Check.Refactor.FlatMapFilter,
    ExSlop.Check.Readability.NarratorDoc,
    ExSlop.Check.Readability.DocFalseOnPublicFunction,
    ExSlop.Check.Readability.BoilerplateDocParams,
    ExSlop.Check.Readability.ObviousComment,
    ExSlop.Check.Readability.StepComment,
    ExSlop.Check.Readability.NarratorComment,
    ExSlop.Check.Readability.UnaliasedModuleUse
  ]

  def checks, do: @checks
end
