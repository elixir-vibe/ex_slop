defmodule ExSlop.Check.Refactor.IdentityMapTest do
  use Credo.Test.Case

  alias ExSlop.Check.Refactor.IdentityMap

  test "reports Enum.map(list, fn x -> x end)" do
    """
    defmodule Test do
      def foo(list) do
        Enum.map(list, fn x -> x end)
      end
    end
    """
    |> to_source_file()
    |> run_check(IdentityMap)
    |> assert_issue()
  end

  test "reports list |> Enum.map(fn item -> item end)" do
    """
    defmodule Test do
      def foo(list) do
        list |> Enum.map(fn item -> item end)
      end
    end
    """
    |> to_source_file()
    |> run_check(IdentityMap)
    |> assert_issue()
  end

  test "does NOT report Enum.map with transformation" do
    """
    defmodule Test do
      def foo(list) do
        Enum.map(list, fn x -> x + 1 end)
      end
    end
    """
    |> to_source_file()
    |> run_check(IdentityMap)
    |> refute_issues()
  end

  test "does NOT report Enum.map over tuple destructuring with transformation" do
    """
    defmodule Test do
      def foo(entries) do
        entries
        |> Enum.map(fn {type, url, depth, tries} ->
          {String.to_atom(type), URI.parse(url), depth, tries}
        end)
      end
    end
    """
    |> to_source_file()
    |> run_check(IdentityMap)
    |> refute_issues()
  end

  test "does NOT report Enum.map over map destructuring" do
    """
    defmodule Test do
      def foo(items) do
        Enum.map(items, fn %{name: name} -> %{label: name} end)
      end
    end
    """
    |> to_source_file()
    |> run_check(IdentityMap)
    |> refute_issues()
  end

  test "does NOT report Enum.map with capture" do
    """
    defmodule Test do
      def foo(list) do
        Enum.map(list, &String.trim/1)
      end
    end
    """
    |> to_source_file()
    |> run_check(IdentityMap)
    |> refute_issues()
  end
end
