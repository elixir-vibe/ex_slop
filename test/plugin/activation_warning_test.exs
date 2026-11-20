defmodule ExSlop.Plugin.ActivationWarningTest do
  # Credo <= 1.7 stores `checks` directly on `%Credo.Execution{}`; Credo's `master` branch (1.8 and beyond) moves
  # the checks to `exec.config` (a `%Credo.Execution.RuntimeConfig{}`). For compatibility, we want to run every test
  # against both layouts, building the real struct from whichever version is installed.
  use ExUnit.Case,
    async: true,
    parameterize: [%{layout: :legacy}, %{layout: :runtime_config}]

  alias ExSlop.Plugin.ActivationWarning

  test "active? is true when an ExSlop check is enabled", %{layout: layout} do
    exec =
      build_exec(layout, %{
        enabled: [{Credo.Check.Readability.ModuleDoc, []}, {ExSlop.Check.Refactor.RejectNil, []}]
      })

    assert ActivationWarning.active?(exec)
  end

  test "active? is false when only non-ExSlop checks are enabled", %{layout: layout} do
    exec = build_exec(layout, %{enabled: [{Credo.Check.Readability.ModuleDoc, []}]})

    refute ActivationWarning.active?(exec)
  end

  test "active? is false when an ExSlop check is disabled", %{layout: layout} do
    exec = build_exec(layout, %{enabled: [{ExSlop.Check.Refactor.RejectNil, false}]})

    refute ActivationWarning.active?(exec)
  end

  test "active? stays quiet (true) when the check set is unknown", %{layout: layout} do
    assert ActivationWarning.active?(build_exec(layout, nil))
  end

  test "call/2 returns the exec unchanged", %{layout: layout} do
    exec = build_exec(layout, %{enabled: [{Credo.Check.Readability.ModuleDoc, []}]})

    assert ActivationWarning.call(exec, []) == exec
  end

  defp build_exec(:legacy, checks) do
    if struct_field?(Credo.Execution, :checks) do
      Credo.Execution |> struct() |> Map.replace!(:checks, checks)
    else
      %{checks: checks}
    end
  end

  defp build_exec(:runtime_config, checks) do
    if Code.ensure_loaded?(Credo.Execution.RuntimeConfig) do
      config = Credo.Execution.RuntimeConfig |> struct() |> Map.replace!(:checks, checks)
      Credo.Execution |> struct() |> Map.replace!(:config, config)
    else
      %{config: %{checks: checks}}
    end
  end

  defp struct_field?(module, field) do
    module |> struct() |> Map.has_key?(field)
  end
end
