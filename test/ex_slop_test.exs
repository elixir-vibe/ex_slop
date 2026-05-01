defmodule ExSlopTest do
  use Credo.Test.Case

  test "recommended aggregate runs ExSlop checks" do
    """
    defmodule Example do
      def foo(items), do: items |> Enum.sort() |> Enum.reverse()
    end
    """
    |> to_source_file()
    |> run_check(ExSlop, :recommended)
    |> assert_issue()
  end

  test "checks includes ported Credence-inspired checks" do
    assert ExSlop.Check.Refactor.UseMapJoin in ExSlop.checks()
    assert ExSlop.Check.Refactor.LengthInGuard in ExSlop.checks()
  end
end
