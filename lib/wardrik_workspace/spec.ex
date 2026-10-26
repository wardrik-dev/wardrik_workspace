defmodule WardrikWorkspace.Spec do
  @moduledoc """
  A spec is what an agent's file tools reach: the `store` its files are kept in, its `own` tree, and
  the trees `shared` with it, each seen under `shared/<name>/`.
  """

  alias WardrikWorkspace.Mount
  alias WardrikWorkspace.Path

  @enforce_keys [:store, :own]
  defstruct [:store, :own, shared: []]

  @type t() :: %__MODULE__{store: WardrikStore.t(), own: Mount.t(), shared: [Mount.t()]}

  @doc "Builds a spec from `:store`, `:tree`, the agent's own, and `:shared`, its mounts."
  @spec new(keyword()) :: t()
  def new(opts) do
    %__MODULE__{
      store: Keyword.fetch!(opts, :store),
      own: %Mount{tree: Keyword.fetch!(opts, :tree)},
      shared: Keyword.get(opts, :shared, [])
    }
  end

  @doc "Returns the mount `path` is in, and the path within its tree, or why it names no file."
  @spec resolve(t(), term()) :: {:ok, Mount.t(), String.t()} | {:error, String.t()}
  def resolve(spec, path) do
    with {:ok, path} <- Path.normalize(path), do: mounted(spec, path)
  end

  @doc "Returns the path `path` in `mount`'s tree is shown at."
  @spec shown(Mount.t(), String.t()) :: String.t()
  def shown(%Mount{name: nil}, path), do: path
  def shown(%Mount{name: name}, path), do: "shared/#{name}/#{path}"

  @doc "Returns every tree the spec reaches: its own first."
  @spec mounts(t()) :: [Mount.t()]
  def mounts(%__MODULE__{own: own, shared: shared}), do: [own | shared]

  defp mounted(spec, "shared/" <> rest) do
    [name | path] = String.split(rest, "/", parts: 2)

    case {Enum.find(spec.shared, &(&1.name == name)), path} do
      {%Mount{} = mount, [path]} -> {:ok, mount, path}
      _unshared -> {:error, "nothing is shared with you as shared/#{name}"}
    end
  end

  defp mounted(spec, path), do: {:ok, spec.own, path}
end
