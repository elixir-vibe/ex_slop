defmodule ExSlop.Check.Readability.DocRestatesNameTest do
  use Credo.Test.Case

  alias ExSlop.Check.Readability.DocRestatesName

  test "reports @doc that restates create_user" do
    """
    defmodule Test do
      @doc "Creates a new user."
      def create_user(attrs), do: attrs
    end
    """
    |> to_source_file()
    |> run_check(DocRestatesName)
    |> assert_issue()
  end

  test "reports @doc that restates delete_post" do
    """
    defmodule Test do
      @doc "Deletes the given post."
      def delete_post(post), do: post
    end
    """
    |> to_source_file()
    |> run_check(DocRestatesName)
    |> assert_issue()
  end

  test "does NOT report @doc with constraints beyond the name" do
    """
    defmodule Test do
      @doc "Returns {:error, :rate_limited} after 5 failed attempts in 60 seconds."
      def create_session(attrs), do: attrs
    end
    """
    |> to_source_file()
    |> run_check(DocRestatesName)
    |> refute_issues()
  end

  test "does NOT report @doc on function with different name" do
    """
    defmodule Test do
      @doc "Deletes expired tokens."
      def cleanup(opts), do: opts
    end
    """
    |> to_source_file()
    |> run_check(DocRestatesName)
    |> refute_issues()
  end

  test "does NOT report multiline @doc" do
    ~S'''
    defmodule Test do
      @doc """
      Creates a new user.

      Passwords must be at least 12 characters.
      """
      def create_user(attrs), do: attrs
    end
    '''
    |> to_source_file()
    |> run_check(DocRestatesName)
    |> refute_issues()
  end

  test "does NOT report single-word function names" do
    """
    defmodule Test do
      @doc "Creates a new resource."
      def create(attrs), do: attrs
    end
    """
    |> to_source_file()
    |> run_check(DocRestatesName)
    |> refute_issues()
  end
end
