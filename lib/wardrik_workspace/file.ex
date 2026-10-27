defmodule WardrikWorkspace.File do
  @moduledoc """
  A file is what a workspace holds at a path: its `content`, who wrote it last, `by`, and `at`, and
  the `labels` of what the runs that wrote it had read, such as `"outside"`.
  """

  @enforce_keys [:content]
  defstruct [:content, :by, :at, labels: []]

  @type t() :: %__MODULE__{
          content: String.t(),
          by: String.t() | nil,
          at: DateTime.t() | nil,
          labels: [String.t()]
        }

  @doc "Returns the file's labels, none for one written before files kept them."
  @spec labels(t()) :: [String.t()]
  def labels(%__MODULE__{} = file), do: Map.get(file, :labels, [])

  @doc "Answers with `answer`, labelled with what `files` hold, as a tool's answer carries them."
  @spec labelled(map(), [t()]) :: {:ok, map() | ReqLLM.ToolResult.t()}
  def labelled(answer, files) do
    case files |> Enum.flat_map(&labels/1) |> Enum.uniq() |> Enum.sort() do
      [] -> {:ok, answer}
      labels -> {:ok, %ReqLLM.ToolResult{output: answer, metadata: %{labels: labels}}}
    end
  end
end
