defmodule ExSlop.Check.Refactor.SortThenReverseTest do
  use Credo.Test.Case

  alias ExSlop.Check.Refactor.SortThenReverse

  test "reports list |> Enum.sort() |> Enum.reverse()" do
    """
    defmodule Test do
      def foo(list) do
        list |> Enum.sort() |> Enum.reverse()
      end
    end
    """
    |> to_source_file()
    |> run_check(SortThenReverse)
    |> assert_issue()
  end

  test "reports Enum.reverse(Enum.sort(list))" do
    """
    defmodule Test do
      def foo(list) do
        Enum.reverse(Enum.sort(list))
      end
    end
    """
    |> to_source_file()
    |> run_check(SortThenReverse)
    |> assert_issue()
  end

  test "does NOT report list |> Enum.sort_by(&fun/1) |> Enum.reverse() (tie order differs)" do
    """
    defmodule Test do
      def foo(list) do
        list |> Enum.sort_by(&elem(&1, 1)) |> Enum.reverse()
      end
    end
    """
    |> to_source_file()
    |> run_check(SortThenReverse)
    |> refute_issues()
  end

  test "does NOT report Enum.reverse(Enum.sort_by(list, fun))" do
    """
    defmodule Test do
      def foo(list) do
        Enum.reverse(Enum.sort_by(list, &elem(&1, 1)))
      end
    end
    """
    |> to_source_file()
    |> run_check(SortThenReverse)
    |> refute_issues()
  end

  test "does NOT report list |> Enum.sort() |> Enum.map(& &1.name)" do
    """
    defmodule Test do
      def foo(list) do
        list |> Enum.sort() |> Enum.map(& &1.name)
      end
    end
    """
    |> to_source_file()
    |> run_check(SortThenReverse)
    |> refute_issues()
  end

  test "does NOT report list |> Enum.reverse()" do
    """
    defmodule Test do
      def foo(list) do
        list |> Enum.reverse()
      end
    end
    """
    |> to_source_file()
    |> run_check(SortThenReverse)
    |> refute_issues()
  end
end
