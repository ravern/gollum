defmodule Gollum.Cache do
  @moduledoc """
  Caches the robots.txt files from different hosts in memory.

  Add this module to your supervision tree. Call this module to perform
  pre-fetches, and makes sure the requests don't get repeated.
  """

  use GenServer

  # State contained in GenServer:
  # Tuple of 3 items
  # 1. data:    %{host => %Host{}}
  # 2. pending: %{host => [from_list]}
  # 3. options

  @doc """
  Starts up the cache.

  ## Options

    * `name` - The name of the GenServer. Default value is `Gollum.Cache`.

    * `refresh_secs` - The number of seconds until the robots.txt will be
      refetched from the host. Defaults to `86_400`, which is 1 day.

    * `lazy_refresh` - If this flag is set to true, the file will only be
      refetched from the host if needed. Otherwise, the file will be
      refreshed at the interval specified by `refresh_secs`. Defaults to
      `false`.
  """
  def start_link(opts \\ []) do
    name = opts[:name] || Gollum.Cache
    GenServer.start_link(__MODULE__, {%{}, %{}, opts}, name: name)
  end

  @doc """
  Fetches the robots.txt from a host and stores it in the cache. It will only perform
  the HTTP request if there isn't any current data in the cache, the data is too old
  (specified in the `refresh_secs` option in `start_link/2`) or when the `force` flag
  is set. This function is useful if you know which hosts you need to request beforehand.

  ## Options

    * `name` - The name of the GenServer. Default value is `Gollum.Cache`.

    * `async` - Whether this call is async. If the call is async, `:ok` is always
      returned. The default value is `false`.

    * `force` - If the cache has already fetched from the host, this flag determines
      whether it should force a refresh. Default is `false`.
  """
  @spec fetch(binary, keyword) :: :ok | {:error, term}
  def fetch(host, opts \\ []) when is_binary(host) do
    name  = opts[:name] || Gollum.Catch
    async = opts[:async] || false

    # Cast if async, else call
    if async do
      GenServer.cast(name, {:fetch, host, opts})
      :ok
    else
      GenServer.call(name, {:fetch, host, opts})
    end
  end

  @doc false
  def handle_call({:fetch, host, opts}, {store, pending, opts_2}) do
  end
end
