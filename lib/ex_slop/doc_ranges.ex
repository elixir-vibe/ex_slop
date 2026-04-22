defmodule ExSlop.DocRanges do
  @moduledoc false

  def build(source) do
    source
    |> String.split("\n")
    |> Enum.with_index(1)
    |> find_doc_ranges([])
  end

  def inside_doc?(line_no, ranges) do
    Enum.any?(ranges, fn {start, finish} -> line_no >= start and line_no <= finish end)
  end

  defp find_doc_ranges([], acc), do: acc

  defp find_doc_ranges([{line, line_no} | rest], acc) do
    trimmed = String.trim(line)

    if heredoc_doc_start?(trimmed) do
      delimiter = extract_delimiter(trimmed)
      {end_line_no, remaining} = find_heredoc_end(rest, delimiter)
      find_doc_ranges(remaining, [{line_no, end_line_no} | acc])
    else
      find_doc_ranges(rest, acc)
    end
  end

  defp heredoc_doc_start?(line) do
    trimmed = String.trim_leading(line)

    String.starts_with?(trimmed, "@doc \"\"\"") or
      String.starts_with?(trimmed, "@moduledoc \"\"\"") or
      String.starts_with?(trimmed, "@doc ~S\"\"\"") or
      String.starts_with?(trimmed, "@moduledoc ~S\"\"\"") or
      String.starts_with?(trimmed, "@doc ~s\"\"\"") or
      String.starts_with?(trimmed, "@moduledoc ~s\"\"\"") or
      String.starts_with?(trimmed, "check: \"\"\"")
  end

  defp extract_delimiter(line) do
    if String.contains?(line, ~S(""")) do
      ~S(""")
    else
      ~S(''')
    end
  end

  defp find_heredoc_end([], _delimiter), do: {999_999, []}

  defp find_heredoc_end([{line, line_no} | rest], delimiter) do
    if String.contains?(String.trim(line), delimiter) and
         not heredoc_doc_start?(String.trim(line)) do
      {line_no, rest}
    else
      find_heredoc_end(rest, delimiter)
    end
  end
end
