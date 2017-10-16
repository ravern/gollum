defmodule Gollum do
  @moduledoc """
  Robots.txt parser with caching. Modelled after Kryten (unmaintained library).
  """

  alias Gollum.{Cache, Host}

  @doc """
  Returns whether a url is permitted. `false` will be returned if an error occurs.

  ## Options

    * `name` - The name of the GenServer. Default value is `Gollum.Cache`.

    * `start_if_needed` - Starts the GenServer if it doesn't exist. Defaults to
    `true`.
  """
  @spec permitted?(binary, binary, keyword) :: boolean
  def permitted?(user_agent, url, opts \\ []) do
    name            = opts[:name]            || Gollum.Cache
    start_if_needed = opts[:start_if_needed] || true

    # Tries to start the GenServer
    if start_if_needed do
      Cache.start_link(name: name)
    end

    uri = URI.parse(url)
    host = "#{uri.scheme}://#{uri.host}"
    path = uri.path

    # Fetch if needed
    :ok = Cache.fetch(host, name: name)

    # Check for permission
    host
    |> Cache.get(name: name)
    |> Host.crawlable?(user_agent, path)
  end
end
