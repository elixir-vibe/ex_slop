defmodule ExSlop.Check.Refactor.DuplicateClauseBodyTest do
  use Credo.Test.Case

  alias ExSlop.Check.Refactor.DuplicateClauseBody

  test "flags two defp clauses with identical bodies and different guards" do
    """
    defmodule Example do
      defp sanitize(error) when is_struct(error) do
        Sanitize.message(error)
      end

      defp sanitize(error) when is_atom(error) do
        Sanitize.message(error)
      end

      defp sanitize(_error), do: "unknown"
    end
    """
    |> to_source_file()
    |> run_check(DuplicateClauseBody)
    |> assert_issue(fn issue ->
      assert issue.message =~ "sanitize/1"
      assert issue.message =~ "combine guards"
    end)
  end

  test "does not flag clauses with different bodies" do
    """
    defmodule Example do
      defp format(x) when is_struct(x), do: format_struct(x)
      defp format(x) when is_atom(x), do: format_atom(x)
    end
    """
    |> to_source_file()
    |> run_check(DuplicateClauseBody)
    |> refute_issues()
  end

  test "does not flag clauses without guards" do
    """
    defmodule Example do
      defp handle(%Foo{} = x), do: process(x)
      defp handle(%Bar{} = x), do: process(x)
    end
    """
    |> to_source_file()
    |> run_check(DuplicateClauseBody)
    |> refute_issues()
  end

  test "does not flag a single clause" do
    """
    defmodule Example do
      defp only_one(x) when is_atom(x), do: x
    end
    """
    |> to_source_file()
    |> run_check(DuplicateClauseBody)
    |> refute_issues()
  end

  test "flags when bodies are structurally identical despite different guard details" do
    """
    defmodule Example do
      defp add_llm_opts(payload, opts) when is_list(opts) and opts != [] do
        Map.put(payload, :llm_opts, opts)
      end

      defp add_llm_opts(payload, opts) when is_map(opts) and map_size(opts) > 0 do
        Map.put(payload, :llm_opts, opts)
      end
    end
    """
    |> to_source_file()
    |> run_check(DuplicateClauseBody)
    |> assert_issue()
  end

  test "does not flag public functions" do
    """
    defmodule Example do
      def handle(x) when is_struct(x), do: process(x)
      def handle(x) when is_atom(x), do: process(x)
    end
    """
    |> to_source_file()
    |> run_check(DuplicateClauseBody)
    |> refute_issues()
  end

  test "does not flag clauses across different functions" do
    """
    defmodule Example do
      defp foo(x) when is_atom(x), do: x
      defp bar(x) when is_atom(x), do: x
    end
    """
    |> to_source_file()
    |> run_check(DuplicateClauseBody)
    |> refute_issues()
  end

  test "does not flag clauses across different arities" do
    """
    defmodule Example do
      defp foo(x) when is_atom(x), do: x
      defp foo(x, y) when is_atom(x), do: x
    end
    """
    |> to_source_file()
    |> run_check(DuplicateClauseBody)
    |> refute_issues()
  end
end
