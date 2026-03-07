defmodule ExSlop.Check.Readability.DocFalseOnPublicFunctionTest do
  use Credo.Test.Case

  alias ExSlop.Check.Readability.DocFalseOnPublicFunction

  test "reports @doc false on public def" do
    """
    defmodule Test do
      @doc false
      def changeset(struct, params), do: struct
    end
    """
    |> to_source_file()
    |> run_check(DocFalseOnPublicFunction)
    |> assert_issue()
  end

  test "does NOT report @doc false on defp" do
    """
    defmodule Test do
      @doc false
      defp internal(x), do: x
    end
    """
    |> to_source_file()
    |> run_check(DocFalseOnPublicFunction)
    |> refute_issues()
  end

  test "does NOT report @doc false with @impl true" do
    """
    defmodule Test do
      @doc false
      @impl true
      def handle_call(msg, from, state), do: {:reply, :ok, state}
    end
    """
    |> to_source_file()
    |> run_check(DocFalseOnPublicFunction)
    |> refute_issues()
  end

  test "does NOT report @doc false on child_spec" do
    """
    defmodule Test do
      @doc false
      def child_spec(opts), do: opts
    end
    """
    |> to_source_file()
    |> run_check(DocFalseOnPublicFunction)
    |> refute_issues()
  end

  test "does NOT report @doc false on init" do
    """
    defmodule Test do
      @doc false
      def init(args), do: {:ok, args}
    end
    """
    |> to_source_file()
    |> run_check(DocFalseOnPublicFunction)
    |> refute_issues()
  end

  test "does NOT report @doc false on start_link" do
    """
    defmodule Test do
      @doc false
      def start_link(opts), do: GenServer.start_link(__MODULE__, opts)
    end
    """
    |> to_source_file()
    |> run_check(DocFalseOnPublicFunction)
    |> refute_issues()
  end
end
