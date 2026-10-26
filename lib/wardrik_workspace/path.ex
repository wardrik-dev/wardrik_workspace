defmodule WardrikWorkspace.Path do
  @moduledoc """
  A path names a file within a workspace, as `notes/today.md`. It's normalised before anything reads
  it: `.` parts and repeated slashes go, and one that's absolute, climbs out with `..`, holds a NUL
  or a backslash, or is longer than 1,024 bytes is refused. Folders are only the beginnings of
  paths, so there's nothing to create.

  A glob matches whole paths: `*` within one folder, `?` one character, and `**` across folders, so
  `notes/*.md` is the Markdown files in `notes`, and `**/*.md` every one.
  """

  @max_bytes 1024

  @doc "Returns the path `path` names, normalised, or why it names none."
  @spec normalize(term()) :: {:ok, String.t()} | {:error, String.t()}
  def normalize(path) when is_binary(path) do
    segments = path |> String.split("/") |> Enum.reject(&(&1 in ["", "."]))

    cond do
      not String.valid?(path) or String.contains?(path, [<<0>>, "\\"]) ->
        {:error, "#{inspect(path)} isn't a path; a path is text, with / between its parts"}

      byte_size(path) > @max_bytes ->
        {:error, "a path is at most #{@max_bytes} bytes"}

      String.starts_with?(path, ["/", "~"]) ->
        {:error, "#{path} is absolute; name a path within the workspace, as notes/today.md"}

      ".." in segments ->
        {:error, "#{path} climbs out of the workspace with .."}

      segments == [] ->
        {:error, "#{inspect(path)} names no file"}

      true ->
        {:ok, Enum.join(segments, "/")}
    end
  end

  def normalize(path), do: {:error, "#{inspect(path)} isn't a path"}

  @doc "Returns whether `glob` matches `path`."
  @spec match?(String.t(), String.t()) :: boolean()
  def match?(glob, path), do: Regex.match?(compile(glob), path)

  @doc "Returns the regular expression `glob` is."
  @spec compile(String.t()) :: Regex.t()
  def compile(glob) do
    glob
    |> String.trim_leading("./")
    |> translate([])
    |> then(&Regex.compile!("\\A" <> &1 <> "\\z", "u"))
  end

  defp translate("**/" <> rest, acc), do: translate(rest, ["(?:.*/)?" | acc])
  defp translate("**" <> rest, acc), do: translate(rest, [".*" | acc])
  defp translate("*" <> rest, acc), do: translate(rest, ["[^/]*" | acc])
  defp translate("?" <> rest, acc), do: translate(rest, ["[^/]" | acc])

  defp translate(<<char::utf8, rest::binary>>, acc),
    do: translate(rest, [Regex.escape(<<char::utf8>>) | acc])

  defp translate("", acc), do: acc |> Enum.reverse() |> IO.iodata_to_binary()
end
