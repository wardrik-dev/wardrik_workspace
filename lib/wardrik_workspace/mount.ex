defmodule WardrikWorkspace.Mount do
  @moduledoc """
  A mount is a tree an agent sees, by its `name` and the `tree` it holds: its own, or one shared with
  it under `shared/<name>/`. `mode` is `:write`, or `:read` where it may only read.
  """

  @enforce_keys [:tree]
  defstruct [:name, :tree, mode: :write]

  @type t() :: %__MODULE__{name: String.t() | nil, tree: String.t(), mode: :read | :write}
end
