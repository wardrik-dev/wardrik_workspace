defmodule WardrikWorkspace do
  @moduledoc """
  Files for agents: a tree of their own, kept in a `WardrikStore` so it outlives the node, trees
  they share, and files read into every turn. It's a `WardrikCore.Capability` that offers six file
  tools, `read_file`, `write_file`, `edit_file`, `list_files`, `search_files` and `delete_file`:

      WardrikCore.start_agent(
        agent_id: "acme/triage",
        model: "anthropic:claude-haiku-4-5",
        capabilities: [{WardrikWorkspace, store: store, tree: "agents/acme/agent/triage"}],
        middleware: [{WardrikWorkspace.Context, store: store, tree: "agents/acme/agent/triage", files: ["MEMORY.md"]}]
      )

  It takes `:store`, `:tree`, the agent's own, and `:shared`, the `WardrikWorkspace.Mount`s of trees
  shared with it. See `WardrikWorkspace.Tools` for what each tool takes, and
  `WardrikWorkspace.Context` for what an agent reads as each turn begins.

  Reach for this when an agent should keep notes, or work on files with others.
  """

  @behaviour WardrikCore.Capability

  @impl WardrikCore.Capability
  def tools(_context, opts),
    do: opts |> WardrikWorkspace.Spec.new() |> WardrikWorkspace.Tools.build()
end
