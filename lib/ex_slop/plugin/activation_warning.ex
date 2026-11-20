defmodule ExSlop.Plugin.ActivationWarning do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.CLI.Output.UI

  @impl true
  def call(exec, _opts) do
    if not active?(exec), do: warn()

    exec
  end

  @doc false
  def active?(exec) do
    case enabled_checks(exec) do
      enabled when is_list(enabled) ->
        Enum.any?(enabled, fn
          {_module, false} -> false
          {module, _params} -> module in ExSlop.checks()
        end)

      # Stay quiet when the ExSlop check set can't be determined.
      _ ->
        true
    end
  end

  # Credo 1.8+ moves runtime config (including `checks`) from `%Credo.Execution{}` into `exec.config`
  defp enabled_checks(%{config: %{checks: %{enabled: enabled}}}), do: enabled
  defp enabled_checks(%{checks: %{enabled: enabled}}), do: enabled
  defp enabled_checks(_exec), do: nil

  defp warn do
    UI.warn([
      :yellow,
      "warning: ",
      :reset,
      "ExSlop is registered as a plugin but none of its checks are active. ",
      "Your `.credo.exs` declares an explicit `checks.enabled` list, which Credo ",
      "treats as authoritative — the plugin's default checks are discarded. ",
      "Append them to your `enabled` list:\n\n",
      "    ] ++ Enum.map(ExSlop.recommended_checks(), &{&1, []}),\n"
    ])
  end
end
