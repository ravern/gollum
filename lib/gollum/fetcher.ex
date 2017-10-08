defmodule Gollum.Fetcher do
  @moduledoc """
  In charge of fetching the actual robots.txt files.
  """

  @doc """
  Fetches the robots.txt file from the specified host. Simply performs
  a `GET` request to the domain via `HTTPoison`.
  """
  @spec fetch(binary, keyword) :: {:ok, binary} | {:error, term}
  def fetch(domain, opts) do
    headers = [
      {"User-Agent", opts[:user_agent] || "Gollum"},
    ]
    other_opts = [
      follow_redirect: true,
      ssl: [{:versions, [:'tlsv1.2']}],
    ]
    opts = Keyword.merge(opts, other_opts)

    # Make the request via HTTPoison and return the ok | error tuple
    case HTTPoison.get("#{domain}/robots.txt", headers, opts) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
      {:ok, _response} ->
        {:error, :no_robots_file}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
