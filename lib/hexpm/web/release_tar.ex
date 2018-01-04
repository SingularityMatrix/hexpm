defmodule Hexpm.Web.ReleaseTar do
  def metadata(binary) do
    case Hex.Tar.unpack({:binary, binary}, :memory) do
      {:ok, {metadata, checksum, _files}} ->
        {:ok, guess_build_tool(metadata), Base.encode16(checksum)}

      {:error, reason} ->
        {:error, Hex.Tar.format_error(reason)}
    end
  end

  @build_tools [
    {"mix.exs"     , "mix"},
    {"rebar.config", "rebar"},
    {"rebar"       , "rebar"},
    {"Makefile"    , "make"},
    {"Makefile.win", "make"}
  ]

  defp guess_build_tool(%{"build_tools" => _} = meta) do
    meta
  end

  defp guess_build_tool(meta) do
    base_files =
      (meta["files"] || [])
      |> Enum.filter(&(Path.dirname(&1) == "."))
      |> MapSet.new()

    build_tools =
      Enum.flat_map(@build_tools, fn {file, tool} ->
        if file in base_files,
            do: [tool],
          else: []
      end)
      |> Enum.uniq()

    if build_tools != [] do
      Map.put(meta, "build_tools", build_tools)
    else
      meta
    end
  end
end
