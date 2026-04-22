defmodule ExSlop.Check.Readability.ObviousCommentTest do
  use Credo.Test.Case

  alias ExSlop.Check.Readability.ObviousComment

  test "reports short obvious comment" do
    """
    defmodule Test do
      def foo do
        # Fetch the user
        Repo.get(User, id)
      end
    end
    """
    |> to_source_file()
    |> run_check(ObviousComment)
    |> assert_issue()
  end

  test "reports 'Create the changeset'" do
    """
    defmodule Test do
      def foo do
        # Create the changeset
        User.changeset(user, attrs)
      end
    end
    """
    |> to_source_file()
    |> run_check(ObviousComment)
    |> assert_issue()
  end

  test "reports 'Return the result'" do
    """
    defmodule Test do
      def foo do
        # Return the result
        {:ok, result}
      end
    end
    """
    |> to_source_file()
    |> run_check(ObviousComment)
    |> assert_issue()
  end

  test "does NOT report comment with technical detail (numbers)" do
    """
    defmodule Test do
      def foo do
        # Fetch the connection from the pool, blocking up to 5s
        conn = checkout()
      end
    end
    """
    |> to_source_file()
    |> run_check(ObviousComment)
    |> refute_issues()
  end

  test "does NOT report comment explaining WHY" do
    """
    defmodule Test do
      def foo do
        # Fetch the user to avoid N+1 in the template
        user = Repo.get(User, id)
      end
    end
    """
    |> to_source_file()
    |> run_check(ObviousComment)
    |> refute_issues()
  end

  test "does NOT report long comment" do
    """
    defmodule Test do
      def foo do
        # Validate the JWT signature against the JWKS endpoint to prevent token forgery
        validate_jwt(token)
      end
    end
    """
    |> to_source_file()
    |> run_check(ObviousComment)
    |> refute_issues()
  end

  test "does NOT report TODO comments" do
    """
    defmodule Test do
      def foo do
        # TODO: Fetch the user asynchronously
        Repo.get(User, id)
      end
    end
    """
    |> to_source_file()
    |> run_check(ObviousComment)
    |> refute_issues()
  end

  test "does NOT report non-matching comments" do
    """
    defmodule Test do
      def foo do
        # Preload to avoid N+1
        Repo.preload(user, :posts)
      end
    end
    """
    |> to_source_file()
    |> run_check(ObviousComment)
    |> refute_issues()
  end

  test "reports configured string prefix" do
    """
    defmodule Test do
      def foo do
        # Hydrate the cache
        hydrate_cache()
      end
    end
    """
    |> to_source_file()
    |> run_check(ObviousComment, additional_keywords: ["Hydrate the"])
    |> assert_issue()
  end

  test "reports configured regex" do
    """
    defmodule Test do
      def foo do
        # Hydrate the cache
        hydrate_cache()

        # Hydrate something else (this one shouldn't be flagged)
        hydrate_something_else()
      end
    end
    """
    |> to_source_file()
    |> run_check(ObviousComment, additional_keywords: [~r/\AHydrate\s+(?:the|a|an)\s/i])
    |> assert_issue()
  end

  test "does NOT report configured string when it is not at the comment start" do
    """
    defmodule Test do
      def foo do
        # We should hydrate the cache
        hydrate_cache()
      end
    end
    """
    |> to_source_file()
    |> run_check(ObviousComment, additional_keywords: ["Hydrate the"])
    |> refute_issues()
  end
end
