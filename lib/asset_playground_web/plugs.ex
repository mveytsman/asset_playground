defmodule Plugs.DepsLoader do
  @moduledoc """
  Load Javascirpt modules correctly by redirecting directory paths to the right js file
  and allowing loading javascript directly from deps

  Important: it should come before Plug.Static in the pipeline
  """

  @behaviour Plug

  import Plug.Conn

  @allowed_methods ~w(GET HEAD)

  @impl true
  def init(opts) do
    %{
      at: Keyword.fetch!(opts, :at) |> Plug.Router.Utils.split(),
      deps:
        for {name, %{base: base, files: files}} <- Keyword.fetch!(opts, :deps), into: %{} do
          {Atom.to_string(name), %{base: Application.app_dir(name, base), files: files}}
        end
    }
  end

  @impl true
  def call(
        %Plug.Conn{method: method, path_info: path_info} = conn,
        %{at: at, deps: deps}
      )
      when method in @allowed_methods do
    segments = subset(at, path_info)

    with {:found, path} <- dep_path(segments, deps),
         {:ok, content} <- File.read(path) do
      conn
      |> put_resp_header("content-type", "application/javascript")
      |> send_resp(200, content)
    else
      {:redirect, path} ->
        conn
        |> put_resp_header("location", path)
        |> send_resp(302, "")
        |> halt()

      _ ->
        conn
    end
  end

  def call(conn, _opts), do: conn

  defp dep_path([dep], deps) do
    case Map.get(deps, dep) do
      %{files: [default | _]} ->
        {:redirect, Path.join([dep, default])}

      _ ->
        :notfound
    end
  end

  defp dep_path([dep | segments], deps) do
    with %{base: base, files: files} <- Map.get(deps, dep),
         path <- Path.join(segments),
         true <- Enum.member?(files, path) do
      {:found, Path.join(base, path)}
    else
      _ ->
        :notfound
    end
  end

  defp dep_path(_segments, _deps), do: :notfound

  defp subset([h | expected], [h | actual]), do: subset(expected, actual)
  defp subset([], actual), do: actual
  defp subset(_, _), do: []
end

defmodule Plugs.JavascriptRedirector do
  @moduledoc """
  Redirect directories to index.js if encountering a javascript module

  e.g. /js/foo/ redirects to /js/foo/index.js
  """

  @behaviour Plug

  import Plug.Conn

  @allowed_methods ~w(GET HEAD)

  @impl true
  def init(opts) do
    %{
      at: Keyword.fetch!(opts, :at) |> Plug.Router.Utils.split(),
      # TODO: support everything Plug.Static does with regards to :from

      priv_path: Keyword.fetch!(opts, :from) |> :code.priv_dir() |> Path.join("static/js/")
    }
  end

  @impl true
  def call(
        %Plug.Conn{method: method, path_info: path_info} = conn,
        %{at: at, priv_path: priv_path}
      )
      when method in @allowed_methods do
    segments = subset(at, path_info)

    if segments != [] && File.dir?(Path.join([priv_path | segments])) do
      conn
      |> put_resp_header("location", Path.join(conn.request_path, "index.js"))
      |> send_resp(302, "")
      |> halt()
    else
      conn
    end
  end

  def call(conn, _opts), do: conn

  defp subset([h | expected], [h | actual]), do: subset(expected, actual)
  defp subset([], actual), do: actual
  defp subset(_, _), do: []
end
