defmodule ExSlop.Check.Warning.DualKeyAccessTest do
  use Credo.Test.Case

  alias ExSlop.Check.Warning.DualKeyAccess

  test "reports Map.get with atom || Map.get with matching string" do
    """
    defmodule Example do
      def extract(usage) do
        input = Map.get(usage, :input_tokens) || Map.get(usage, "input_tokens") || 0
        input
      end
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> assert_issue()
  end

  test "reports Map.get mixed with Map.fetch!" do
    """
    defmodule Example do
      def extract(widget) do
        Map.get(widget, :id) || Map.fetch!(widget, "id")
      end
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> assert_issue()
  end

  test "reports get_in atom and string paths" do
    """
    defmodule Example do
      def extract(event) do
        get_in(event.data, [:path]) || get_in(event.data, ["path"])
      end
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> assert_issue()
  end

  test "reports access syntax atom and string keys" do
    """
    defmodule Example do
      def extract(payload) do
        payload[:kind] || payload["kind"]
      end
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> assert_issue()
  end

  test "reports nested OR chains" do
    """
    defmodule Example do
      def extract(tool) do
        Map.get(tool, :args) || Map.get(tool, "args") || Map.get(tool, :params) || Map.get(tool, "params")
      end
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> assert_issue()
  end

  test "does NOT report when atom and string keys differ" do
    """
    defmodule Example do
      def extract(usage) do
        input = Map.get(usage, :input_tokens) || Map.get(usage, "input_count")
        input
      end
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> refute_issues()
  end

  test "does NOT report single Map.get" do
    """
    defmodule Example do
      def extract(usage) do
        Map.get(usage, :input_tokens, 0)
      end
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> refute_issues()
  end

  test "does NOT report Map.get with different maps" do
    """
    defmodule Example do
      def extract(a, b) do
        Map.get(a, :key) || Map.get(b, "key")
      end
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> refute_issues()
  end
end
