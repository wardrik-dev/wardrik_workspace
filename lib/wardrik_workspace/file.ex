defmodule WardrikWorkspace.File do
  @moduledoc "A file is what a workspace holds at a path: its `content`, who wrote it last, `by`, and `at`."

  @enforce_keys [:content]
  defstruct [:content, :by, :at]

  @type t() :: %__MODULE__{content: String.t(), by: String.t() | nil, at: DateTime.t() | nil}
end
