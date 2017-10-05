defmodule Gollum.Fetcher do
  @moduledoc false

  # Fetch from specified host.
  def fetch(host, opts) do
    headers = [
      {"User-Agent", opts[:user_agent]},
    ]
    other_opts = [
      follow_redirect: true,
      ssl: [{:versions, [:'tlsv1.2']}],
    ]
    opts = Keyword.merge(opts, other_opts)

    # Make the request via HTTPoison and return the ok | error tuple
    case HTTPoison.get("#{host}/robots.txt", headers, opts) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}
      {:ok, _response} ->
        {:error, :no_robots_file}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
