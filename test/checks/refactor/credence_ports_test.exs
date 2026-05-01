defmodule ExSlop.Check.Refactor.CredencePortsTest do
  use Credo.Test.Case

  alias ExSlop.Check.Refactor.ExplicitSumReduce
  alias ExSlop.Check.Refactor.GraphemesLength
  alias ExSlop.Check.Refactor.LengthInGuard
  alias ExSlop.Check.Refactor.ListFold
  alias ExSlop.Check.Refactor.ListLast
  alias ExSlop.Check.Refactor.ManualStringReverse
  alias ExSlop.Check.Refactor.PreferEnumSlice
  alias ExSlop.Check.Refactor.RedundantEnumJoinSeparator
  alias ExSlop.Check.Refactor.SortForTopK
  alias ExSlop.Check.Refactor.SortThenAt
  alias ExSlop.Check.Refactor.UseMapJoin

  test "reports redundant empty Enum.join separator" do
    """
    defmodule Example do
      def join(parts), do: Enum.join(parts, "")
    end
    """
    |> to_source_file()
    |> run_check(RedundantEnumJoinSeparator)
    |> assert_issue()
  end

  test "does NOT report Enum.join with a meaningful separator" do
    """
    defmodule Example do
      def join(parts), do: Enum.join(parts, ",")
    end
    """
    |> to_source_file()
    |> run_check(RedundantEnumJoinSeparator)
    |> refute_issues()
  end

  test "reports Enum.map followed by Enum.join" do
    """
    defmodule Example do
      def labels(items), do: items |> Enum.map(&to_string/1) |> Enum.join(",")
    end
    """
    |> to_source_file()
    |> run_check(UseMapJoin)
    |> assert_issue()
  end

  test "reports Enum.drop followed by Enum.take" do
    """
    defmodule Example do
      def page(items, offset, limit), do: items |> Enum.drop(offset) |> Enum.take(limit)
    end
    """
    |> to_source_file()
    |> run_check(PreferEnumSlice)
    |> assert_issue()
  end

  test "reports counting String.graphemes" do
    """
    defmodule Example do
      def size(value), do: value |> String.graphemes() |> length()
    end
    """
    |> to_source_file()
    |> run_check(GraphemesLength)
    |> assert_issue()
  end

  test "does NOT report String.length" do
    """
    defmodule Example do
      def size(value), do: String.length(value)
    end
    """
    |> to_source_file()
    |> run_check(GraphemesLength)
    |> refute_issues()
  end

  test "reports manual String.reverse" do
    """
    defmodule Example do
      def reverse(value), do: value |> String.graphemes() |> Enum.reverse() |> Enum.join()
    end
    """
    |> to_source_file()
    |> run_check(ManualStringReverse)
    |> assert_issue()
  end

  test "reports sort then Enum.at" do
    """
    defmodule Example do
      def first(items), do: items |> Enum.sort() |> Enum.at(0)
    end
    """
    |> to_source_file()
    |> run_check(SortThenAt)
    |> assert_issue()
  end

  test "reports sort then top-k" do
    """
    defmodule Example do
      def first(items), do: items |> Enum.sort() |> Enum.take(1)
    end
    """
    |> to_source_file()
    |> run_check(SortForTopK)
    |> assert_issue()
  end

  test "does NOT report sort used as sorted list" do
    """
    defmodule Example do
      def sorted(items), do: items |> Enum.sort() |> Enum.map(& &1.name)
    end
    """
    |> to_source_file()
    |> run_check(SortForTopK)
    |> refute_issues()
  end

  test "reports List.foldl" do
    """
    defmodule Example do
      def sum(items), do: List.foldl(items, 0, fn item, acc -> item + acc end)
    end
    """
    |> to_source_file()
    |> run_check(ListFold)
    |> assert_issue()
  end

  test "reports List.last" do
    """
    defmodule Example do
      def last(items), do: List.last(items)
    end
    """
    |> to_source_file()
    |> run_check(ListLast)
    |> assert_issue()
  end

  test "reports length in guard" do
    """
    defmodule Example do
      def empty?(items) when length(items) == 0, do: true
      def empty?(_items), do: false
    end
    """
    |> to_source_file()
    |> run_check(LengthInGuard)
    |> assert_issue()
  end

  test "does NOT report length outside guard" do
    """
    defmodule Example do
      def size(items), do: length(items)
    end
    """
    |> to_source_file()
    |> run_check(LengthInGuard)
    |> refute_issues()
  end

  test "reports explicit sum reduce" do
    """
    defmodule Example do
      def sum(items), do: Enum.reduce(items, 0, fn item, acc -> item + acc end)
    end
    """
    |> to_source_file()
    |> run_check(ExplicitSumReduce)
    |> assert_issue()
  end
end
