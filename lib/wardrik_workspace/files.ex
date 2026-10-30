defmodule WardrikWorkspace.Files do
  @moduledoc """
  Stores trees of files in a `WardrikStore`, each file with its own version.

  Every change is made over a version:

    * `nil` - writes only where no file is.
    * a version - writes only if the file is still at that version.

  Otherwise it returns `{:error, :conflict}`. This keeps two writers from losing each other's work.

  Tree names are opaque: tree `shared/acme` doesn't contain tree `shared/acme/runbooks`.
  """

  alias WardrikWorkspace.File

  @typedoc "A file's version, as the model is shown it."
  @type version() :: String.t()

  @doc "Returns the file at `path` in `tree`, with its version, or `:none`."
  @spec read(WardrikStore.t(), String.t(), String.t()) :: {:ok, File.t(), version()} | :none
  def read(store, tree, path) do
    case WardrikStore.lookup(scoped(store), key(tree, path)) do
      {%File{} = file, vsn} -> {:ok, file, version(vsn)}
      nil -> :none
    end
  end

  @doc """
  Writes `file` at `path` in `tree`.

  With a `nil` version, writes only where no file is. Otherwise writes only over `version`.
  Returns `{:error, :conflict}` if that doesn't hold.
  """
  @spec write(WardrikStore.t(), String.t(), String.t(), File.t(), version() | nil) ::
          {:ok, version()} | {:error, :conflict | term()}
  def write(store, tree, path, %File{} = file, version) do
    with {:ok, vsn} <- vsn(version),
         {:ok, written} <- WardrikStore.put(scoped(store), key(tree, path), file, if_vsn: vsn),
         do: {:ok, version(written)}
  end

  @doc "Deletes the file at `path` in `tree`. Returns `{:error, :conflict}` unless it's still at `version`."
  @spec delete(WardrikStore.t(), String.t(), String.t(), version()) ::
          :ok | {:error, :conflict | term()}
  def delete(store, tree, path, version) do
    with {:ok, vsn} <- vsn(version),
         do: WardrikStore.delete(scoped(store), key(tree, path), if_vsn: vsn)
  end

  @doc "Returns every path in `tree`."
  @spec paths(WardrikStore.t(), String.t()) :: [String.t()]
  def paths(store, tree) do
    prefix = tree <> "//"

    for key <- WardrikStore.keys(scoped(store), prefix),
        do: String.replace_prefix(key, prefix, "")
  end

  @doc "Returns every file in `tree`, with its path and version."
  @spec list(WardrikStore.t(), String.t()) :: [{String.t(), File.t(), version()}]
  def list(store, tree) do
    for path <- paths(store, tree),
        {:ok, file, version} <- [read(store, tree, path)],
        do: {path, file, version}
  end

  defp scoped(store), do: WardrikStore.scope(store, "wardrik_workspace")
  defp key(tree, path), do: tree <> "//" <> path

  defp version(vsn), do: vsn |> :erlang.term_to_binary() |> Base.url_encode64(padding: false)

  defp vsn(nil), do: {:ok, nil}

  defp vsn(version) when is_binary(version) do
    case Base.url_decode64(version, padding: false) do
      {:ok, binary} -> term(binary)
      :error -> {:error, :conflict}
    end
  end

  defp term(binary) do
    {:ok, :erlang.binary_to_term(binary, [:safe])}
  rescue
    ArgumentError -> {:error, :conflict}
  end
end
