defmodule ExSlop.Check.Readability.HungarianNameTest do
  use Credo.Test.Case

  alias ExSlop.Check.Readability.HungarianName

  test "reports user_map = %{}" do
    """
    defmodule Test do
      def foo do
        user_map = %{name: "Dan"}
      end
    end
    """
    |> to_source_file()
    |> run_check(HungarianName)
    |> assert_issue()
  end

  test "reports items_list = []" do
    """
    defmodule Test do
      def foo do
        items_list = []
      end
    end
    """
    |> to_source_file()
    |> run_check(HungarianName)
    |> assert_issue()
  end

  test "does NOT report _ignored_list = []" do
    """
    defmodule Test do
      def foo do
        _ignored_list = []
      end
    end
    """
    |> to_source_file()
    |> run_check(HungarianName)
    |> refute_issues()
  end

  test "does NOT report plain user = %{}" do
    """
    defmodule Test do
      def foo do
        user = %{name: "Dan"}
      end
    end
    """
    |> to_source_file()
    |> run_check(HungarianName)
    |> refute_issues()
  end

  test "does NOT report legitimate compound word allow_list" do
    """
    defmodule Test do
      def foo do
        allow_list = [:admin, :moderator]
      end
    end
    """
    |> to_source_file()
    |> run_check(HungarianName)
    |> refute_issues()
  end

  test "does NOT report destructured pattern match" do
    """
    defmodule Test do
      def foo(config) do
        %{items_list: items_list} = config
      end
    end
    """
    |> to_source_file()
    |> run_check(HungarianName)
    |> refute_issues()
  end
end
