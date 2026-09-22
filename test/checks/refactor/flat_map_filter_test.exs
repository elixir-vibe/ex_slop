defmodule ExSlop.Check.Refactor.FlatMapFilterTest do
  use Credo.Test.Case

  alias ExSlop.Check.Refactor.FlatMapFilter

  test "reports Enum.flat_map with if [x]/[] pattern" do
    """
    defmodule Example do
      def active_items(items) do
        Enum.flat_map(items, fn item ->
          if item.active, do: [item], else: []
        end)
      end
    end
    """
    |> to_source_file()
    |> run_check(FlatMapFilter)
    |> assert_issue()
  end

  test "reports piped Enum.flat_map with if [x]/[] pattern" do
    """
    defmodule Example do
      def active_items(items) do
        items
        |> Enum.flat_map(fn item ->
          if item.active, do: [item], else: []
        end)
      end
    end
    """
    |> to_source_file()
    |> run_check(FlatMapFilter)
    |> assert_issue()
  end

  test "reports inverted if []/[x] pattern" do
    """
    defmodule Example do
      def inactive_items(items) do
        Enum.flat_map(items, fn item ->
          if item.active, do: [], else: [item]
        end)
      end
    end
    """
    |> to_source_file()
    |> run_check(FlatMapFilter)
    |> assert_issue()
  end

  test "does NOT report flat_map whose singleton transforms the element" do
    """
    defmodule Example do
      def doubled_positives(items) do
        Enum.flat_map(items, fn x ->
          if x > 0, do: [x * 2], else: []
        end)
      end
    end
    """
    |> to_source_file()
    |> run_check(FlatMapFilter)
    |> refute_issues()
  end

  test "does NOT report flat_map whose singleton holds a different variable" do
    """
    defmodule Example do
      def children(items) do
        Enum.flat_map(items, fn %{child: child} = item ->
          if item.active, do: [child], else: []
        end)
      end
    end
    """
    |> to_source_file()
    |> run_check(FlatMapFilter)
    |> refute_issues()
  end

  test "does NOT report legitimate flat_map with multi-element lists" do
    """
    defmodule Example do
      def expand(items) do
        Enum.flat_map(items, fn item ->
          if item.has_children, do: [item | item.children], else: [item]
        end)
      end
    end
    """
    |> to_source_file()
    |> run_check(FlatMapFilter)
    |> refute_issues()
  end

  test "does NOT report Enum.filter" do
    """
    defmodule Example do
      def active_items(items) do
        Enum.filter(items, & &1.active)
      end
    end
    """
    |> to_source_file()
    |> run_check(FlatMapFilter)
    |> refute_issues()
  end

  test "does NOT report flat_map with for comprehension" do
    """
    defmodule Example do
      def expand(items) do
        for item <- items, child <- item.children, do: child
      end
    end
    """
    |> to_source_file()
    |> run_check(FlatMapFilter)
    |> refute_issues()
  end
end
