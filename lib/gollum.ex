defmodule Gollum do
  @moduledoc """
  Robots.txt parser with caching. Modelled after Kryten.

  Usage of `Gollum` would simply be to call `Gollum.crawlable?/3` to obtain
  whether a certain URL is permitted for the specified user agent.

  `Gollum` is an OTP app (For the cache) so just remember to specify it in the
  `extra_applications` key in your `mix.exs` to ensure it is started.

  `Gollum` allows for some configuration in your `config.exs` file. The following
  shows their default values. They are all optional.
  ```
  config :gollum,
    name: Gollum.Cache, # Name of the Cache GenServer
    refresh_secs: 86_400, # Amount of time before the robots.txt will be refetched
    lazy_refresh: false, # Whether to setup a timer that auto-refetches, or to only refetch when requested
    user_agent: "Gollum" # User agent to use when sending the GET request for the robots.txt
  ```

  You can also setup a `Gollum.Cache` manually using `Gollum.Cache.start_link/1`
  and add it to your supervision tree.
  """

  alias Gollum.{Cache, Host}

  @doc """
  Returns whether a url is permitted. `false` will be returned if an error occurs.

  ## Options

    * `name` - The name of the GenServer. Default value is `Gollum.Cache`.

  Any other options passed will be passed to the internal `Cache.start_link/1` call.

  ## Examples
  ```
  iex> Gollum.crawlable?("hello", "https://google.com/")
  :crawlable
  iex> Gollum.crawlable?("hello", "https://google.com/m/")
  :uncrawlable
  ```
  """
  @spec crawlable?(binary, binary, keyword) :: :crawlable | :uncrawlable | :undefined
  def crawlable?(user_agent, url, opts \\ []) do
    name = opts[:name] || Gollum.Cache

    uri = URI.parse(url)
    host = "#{uri.scheme}://#{uri.host}"
    path = uri.path || "/"

    case Cache.fetch(host, name: name) do
      {:error, _} -> :crawlable
      :ok ->
        host
        |> Cache.get(name: name)
        |> Host.crawlable?(user_agent, path)
    end
  end
end
