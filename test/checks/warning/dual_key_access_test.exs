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

  test "reports a variable key and its Atom.to_string/1 conversion" do
    """
    defmodule Example do
      def extract(data, key) do
        Map.get(data, key) || Map.get(data, Atom.to_string(key))
      end
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> assert_issue()
  end

  test "reports a variable key and its to_string/1 conversion" do
    """
    defmodule Example do
      def extract(data, key) do
        Map.get(data, to_string(key)) || Map.get(data, key)
      end
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> assert_issue()
  end

  test "reports a variable key and its String.to_atom/1 conversion" do
    """
    defmodule Example do
      def extract(data, key) do
        Map.get(data, key) || Map.fetch!(data, String.to_atom(key))
      end
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> assert_issue()
  end

  test "reports access syntax with a variable key and its String.to_existing_atom/1 conversion" do
    """
    defmodule Example do
      def extract(data, key) do
        data[key] || data[String.to_existing_atom(key)]
      end
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> assert_issue()
  end

  test "reports access syntax with a variable key and its Atom.to_string/1 conversion" do
    """
    defmodule Example do
      def extract(data, key) do
        data[key] || data[Atom.to_string(key)] || :default
      end
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> assert_issue()
  end

  test "reports clauses matching the same key as string and atom" do
    """
    defmodule Example do
      defp detail_value(%{"from" => from, "to" => to}), do: {from, to}
      defp detail_value(%{from: from, to: to}), do: {from, to}
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> assert_issue(fn issue -> assert issue.line_no == 2 end)
  end

  test "reports clauses sharing one key across forms in the same argument position" do
    """
    defmodule Example do
      @doc "Handles an event."
      def handle(conn, %{"type" => type} = params) when is_binary(type) do
        {conn, type, params}
      end

      def handle(conn, %{type: type, id: id}) do
        {conn, type, id}
      end

      def handle(conn, _params), do: conn
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> assert_issue()
  end

  test "does NOT report a variable key converted only for a different map" do
    """
    defmodule Example do
      def extract(data, key, fallback) do
        Map.get(data, key) || Map.get(fallback, Atom.to_string(key)) || Map.get(data, key)
      end
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> refute_issues()
  end

  test "does NOT report different variable keys" do
    """
    defmodule Example do
      def extract(data, key, other) do
        Map.get(data, key) || Map.get(data, Atom.to_string(other))
      end
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> refute_issues()
  end

  test "does NOT report clauses matching different keys" do
    """
    defmodule Example do
      defp detail_value(%{"from" => from}), do: from
      defp detail_value(%{to: to}), do: to
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> refute_issues()
  end

  test "does NOT report clauses using the same key form" do
    """
    defmodule Example do
      def handle(%{"type" => "a", "id" => id}), do: {:a, id}
      def handle(%{"type" => "b", "id" => id}), do: {:b, id}
      def handle(%{"type" => type}), do: type
      def handle(%{name: name}), do: name
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> refute_issues()
  end

  test "does NOT report the same key form in different argument positions" do
    """
    defmodule Example do
      def merge(%{"id" => id}, _other), do: id
      def merge(_other, %{id: id}), do: id
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> refute_issues()
  end

  test "does NOT report unrelated functions or different arities" do
    """
    defmodule Example do
      def parse(%{"id" => id}), do: id
      def load(%{id: id}), do: id
      def fetch(%{"id" => id}), do: id
      def fetch(%{id: id}, _opts), do: id
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> refute_issues()
  end

  test "does NOT report a single-clause function" do
    """
    defmodule Example do
      def handle(%{"id" => id}), do: id
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> refute_issues()
  end

  test "does NOT report a struct clause next to a string-key map clause" do
    """
    defmodule Example do
      def cast(%Money{amount: amount}), do: {:ok, amount}
      def cast(%{"amount" => amount}), do: {:ok, amount}
    end
    """
    |> to_source_file()
    |> run_check(DualKeyAccess)
    |> refute_issues()
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
