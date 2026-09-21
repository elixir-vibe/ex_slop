defmodule ExSlop.Check.Refactor.WithIdentityElseTest do
  use Credo.Test.Case

  alias ExSlop.Check.Refactor.WithIdentityElse

  test "reports with/else where else is identity and has a catch-all" do
    """
    defmodule Test do
      def foo do
        with {:ok, result} <- do_something() do
          {:ok, result}
        else
          {:error, reason} -> {:error, reason}
          other -> other
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(WithIdentityElse)
    |> assert_issue()
  end

  test "reports with/else whose only clause is a catch-all identity" do
    """
    defmodule Test do
      def foo do
        with {:ok, result} <- do_something() do
          {:ok, result}
        else
          error -> error
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(WithIdentityElse)
    |> assert_issue()
  end

  test "reports non-exhaustive identity else and mentions the raise" do
    """
    defmodule Test do
      def foo do
        with {:ok, result} <- do_something() do
          {:ok, result}
        else
          {:error, reason} -> {:error, reason}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(WithIdentityElse)
    |> assert_issue(fn issue ->
      assert issue.message =~ "raising"
    end)
  end

  test "does NOT mention the raise for an else with a catch-all clause" do
    """
    defmodule Test do
      def foo do
        with {:ok, result} <- do_something() do
          {:ok, result}
        else
          error -> error
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(WithIdentityElse)
    |> assert_issue(fn issue ->
      refute issue.message =~ "raising"
    end)
  end

  test "does NOT report else clauses that project maps" do
    """
    defmodule Test do
      def foo do
        with {:ok, result} <- do_something() do
          {:ok, result}
        else
          %{error: error} -> %{error: error}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(WithIdentityElse)
    |> refute_issues()
  end

  test "does NOT report with/else where else transforms values" do
    """
    defmodule Test do
      def foo do
        with {:ok, result} <- do_something() do
          {:ok, result}
        else
          {:error, reason} -> {:error, :failed, reason}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(WithIdentityElse)
    |> refute_issues()
  end

  test "does NOT report with without else" do
    """
    defmodule Test do
      def foo do
        with {:ok, result} <- do_something() do
          {:ok, result}
        end
      end
    end
    """
    |> to_source_file()
    |> run_check(WithIdentityElse)
    |> refute_issues()
  end
end
