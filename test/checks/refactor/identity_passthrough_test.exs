defmodule ExSlop.Check.Refactor.IdentityPassthroughTest do
  use Credo.Test.Case

  alias ExSlop.Check.Refactor.IdentityPassthrough

  test "reports case where every clause returns what it matched" do
    """
    defmodule Test do
      def foo(result) do
        case result do
          {:ok, value} -> {:ok, value}
          other -> other
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(IdentityPassthrough)
    |> assert_issue()
  end

  test "reports case with identity list patterns and a catch-all" do
    """
    defmodule Test do
      def foo(list) do
        case list do
          [head | tail] -> [head | tail]
          other -> other
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(IdentityPassthrough)
    |> assert_issue()
  end

  test "reports non-exhaustive identity case and mentions the raise" do
    """
    defmodule Test do
      def foo(result) do
        case result do
          {:ok, value} -> {:ok, value}
          {:error, reason} -> {:error, reason}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(IdentityPassthrough)
    |> assert_issue(fn issue ->
      assert issue.message =~ "raising"
    end)
  end

  test "does NOT mention the raise for a case with a catch-all clause" do
    """
    defmodule Test do
      def foo(result) do
        case result do
          {:ok, value} -> {:ok, value}
          other -> other
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(IdentityPassthrough)
    |> assert_issue(fn issue ->
      refute issue.message =~ "raising"
    end)
  end

  test "does NOT report map projections" do
    """
    defmodule Test do
      def foo(value) do
        case value do
          %{a: a} -> %{a: a}
          %{b: b} -> %{b: b}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(IdentityPassthrough)
    |> refute_issues()
  end

  test "does NOT report struct projections" do
    """
    defmodule Test do
      def foo(value) do
        case value do
          %User{name: name} -> %User{name: name}
          nil -> nil
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(IdentityPassthrough)
    |> refute_issues()
  end

  test "does NOT report case that transforms values" do
    """
    defmodule Test do
      def foo(result) do
        case result do
          {:ok, value} -> value
          other -> other
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(IdentityPassthrough)
    |> refute_issues()
  end
end
