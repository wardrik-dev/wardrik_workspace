# WardrikWorkspace

Files for agents: a tree of their own, kept in a [WardrikStore](https://hexdocs.pm/wardrik_store)
so it outlives the node, trees they share, and files read into every turn. With
[Wardrik](https://hexdocs.pm/wardrik), an agent names `files` in its tools and `context` in its
definition, and you're done:

```yaml
tools: [files]
context: [MEMORY.md]
workspace:
  shared:
    team: acme                                  # acme's tree, read and written
    runbooks: {tree: acme/runbooks, mode: read}
```

## Install

```elixir
def deps do
  [
    {:wardrik_workspace, "~> 0.1"}
  ]
end
```

## On WardrikCore alone

It's a capability, for the six file tools, and a middleware, for the files read into every turn:

```elixir
store = WardrikStore.ETS.new(name: MyApp.Store)
tree = "agents/acme/agent/triage"

WardrikCore.start_agent(
  agent_id: "acme/triage",
  model: "anthropic:claude-haiku-4-5",
  capabilities: [{WardrikWorkspace, store: store, tree: tree}],
  middleware: [{WardrikWorkspace.Context, store: store, tree: tree, files: ["MEMORY.md"]}]
)
```

## The file tools

| Tool | What it does |
| --- | --- |
| `read_file` | Reads a file, with its version, numbered by line |
| `write_file` | Writes a file, over the version read, or appends with `append` |
| `edit_file` | Replaces text that appears once, or everywhere with `all` |
| `list_files` | Lists the files a glob matches, newest first |
| `search_files` | Finds the lines a regular expression matches |
| `delete_file` | Deletes a file |

A path is relative to the top of the tree, as `notes/2026-10-01.md`, and a tree shared with the
agent is under `shared/<name>/`. Replacing a file takes the version it was read at, so two writers
never lose each other's work. A tool that can't do what it's asked answers
`%{ok: false, error: %{code: ..., message: ...}}`, and the turn carries on.

Each call says what it acts on, its path or glob, so a policy can name it, as
`allow: [write_file(notes/*)]`.

## Read into every turn

`WardrikWorkspace.Context` adds the `:files` named to the end of the agent's instructions as each
turn begins, with each file's version, the names of the other files at the top of its tree, and the
trees shared with it. Up to 16 KB is read unless `:max_bytes` says otherwise. A file longer than its
share is read from its start and its end, and the agent is asked to rewrite it shorter.
