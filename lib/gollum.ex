defmodule Gollum do
  @moduledoc """
  Robots.txt parser with caching. Modelled after Kryten.
  """

  alias Gollum.{Cache, Host}

  @doc """
  Returns whether a url is permitted. `false` will be returned if an error occurs.

  ## Options

    * `name` - The name of the GenServer. Default value is `Gollum.Cache`.

    * `start_if_needed` - Starts the GenServer if it doesn't exist. Defaults to
    `true`.

  Any other options passed will be passed to the internal `Cache.start_link/1` call.

  ## Examples
  ```
  iex> Gollum.crawlable?("hello", "http://example.com/hello", fetcher: MockFetcher)
  :crawlable
  iex> Gollum.crawlable?("hello", "http://example.com/hey")
  :uncrawlable
  ```
  """
  @spec crawlable?(binary, binary, keyword) :: boolean
  def crawlable?(user_agent, url, opts \\ []) do
    name            = opts[:name]            || Gollum.Cache
    start_if_needed = opts[:start_if_needed] || true

    # Tries to start the GenServer
    if start_if_needed do
      Cache.start_link(opts)
    end

    uri = URI.parse(url)
    host = "#{uri.scheme}://#{uri.host}"
    path = uri.path || "/"

    case Cache.fetch(host, name: name) do
      {:error, _} -> true
      :ok ->
        host
        |> Cache.get(name: name)
        |> Host.crawlable?(user_agent, path)
    end
  end
end
