defmodule ExSlop.Check.Warning.RepoAllThenFilter do
  use Credo.Check,
    id: "EXS1002",
    base_priority: :high,
    category: :warning,
    tags: [:ex_slop],
    explanations: [
      check: """
      `Repo.all(Schema) |> Enum.filter(...)` loads every record into memory
      then filters in Elixir. Use Ecto query conditions instead.

          # bad — loads all users then filters
          Repo.all(User) |> Enum.filter(& &1.active)

          # good — filters at the database
          User |> where(active: true) |> Repo.all()
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # Repo.all(...) |> Enum.filter(...)
  for filter_fun <- [:filter, :reject, :find] do
    defp walk(
           {:|>, _,
            [
              {{:., _, [{:__aliases__, _, repo}, :all]}, _, _},
              {{:., meta, [{:__aliases__, _, [:Enum]}, unquote(filter_fun)]}, _, _}
            ]} = ast,
           ctx
         ) do
      if repo_module?(repo) do
        {ast, put_issue(ctx, issue_for(ctx, meta, unquote(filter_fun)))}
      else
        {ast, ctx}
      end
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp repo_module?([:Repo]), do: true
  defp repo_module?([_ | rest]), do: repo_module?(rest)
  defp repo_module?(_), do: false

  defp issue_for(ctx, meta, filter_fun) do
    format_issue(ctx,
      message:
        "`Repo.all/1 |> Enum.#{filter_fun}/2` loads all records — filter in the Ecto query instead.",
      trigger: "#{filter_fun}",
      line_no: meta[:line]
    )
  end
end
