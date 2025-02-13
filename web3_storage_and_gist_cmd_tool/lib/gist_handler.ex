defmodule Web3StorageAndGistCmdTool.GistHandler do
  @moduledoc """
    See Gist API Docs in: \n
    > https://docs.github.com/en/rest/gists
  """
  alias Web3StorageAndGistCmdTool.Http
  require Logger
  @prefix "https://api.github.com/gists"


  def build_url(username, gist_id) do
    "https://gist.github.com/#{username}/#{gist_id}"
  end
  def build_header(), do: [{"Authorization", "Bearer #{Constants.get_constant(:github_token)}"}]
  def create_gist(payload) do
    headers = build_header()
    Http.http_post(@prefix, payload, headers)
  end

  def update_gist(gist_id, new_payload) do
    url = "#{@prefix}/#{gist_id}"
    headers = build_header()
    Http.http_post(url, new_payload, headers)
  end

  @doc """
    Example:\n
    ```
    %{
      files: %{
        "basic_info.json": %{
          content: "{\n  \"name\": \"NonceGeekDAO\"\n}",
          filename: "basic_info.json",
          language: "JSON",
          raw_url: "https://gist.githubusercontent.com/leeduckgo/220087607d69490980ba59c235b86f59/raw/3a9187c91598183c7dd95691f1d23bd594d74d1d/basic_info.json",
          size: 28,
          truncated: false,
          type: "application/json"
        }
      },
      owner: %{id: 12784118, login: "leeduckgo"}
    }
    ```

    gist_id |> get_gist |> del_types_from_names()
  """
  @spec get_gist(String.t()) :: map()
  def get_gist(gist_id) do
    {:ok, payload} =
      do_get_from_gist(gist_id)
    %{
      files: files,
      owner: %{
        login: user_name,
        id: github_id
      },
      public: if_public,
      description: description
    } =
      ExStructTranslator.to_atom_struct(payload)

    %{
      gist_id: gist_id,
      files: handle_files_type(files),
      owner: %{
        login: user_name,
        id: github_id
      },
      public: if_public,
      description: description
    }
  end

  def do_get_from_gist(gist_id) do
    Logger.info("get from gist: #{@prefix}/#{gist_id}")
    Http.http_get("#{@prefix}/#{gist_id}")
  end

  def del_types_from_names(%{files: files} = payload) do
    files_handled =
      files
      |> Enum.map(fn {file_name, content} ->
        {do_del_types_from_names(file_name), content}
      end)
      |> Enum.into(%{})
    Map.put(payload, :files, files_handled)
  end

  defp do_del_types_from_names(file_name) do
    [file_name_pure, _] =
      file_name
      |> Atom.to_string()
      |> String.split(".")
    file_name_pure
    |> String.to_atom()
  end

  def handle_files_type(files) do
    files
    |> Enum.map(fn {file_name, payload} ->
      handle_file_type(file_name, payload)
    end)
    |> Enum.into(%{})
  end

  def handle_file_type(file_name, %{content: content} = payload) do
    [_file_name_pure, type] =
      file_name
      |> Atom.to_string()
      |> String.split(".")

    content_handled =
      if type == "json" do
        content
        |> Poison.decode!()
        |> ExStructTranslator.to_atom_struct()
      else
        content
      end
    {file_name, Map.put(payload, :content, content_handled)}
  end
end
