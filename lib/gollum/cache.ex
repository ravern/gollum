defmodule Gollum.Cache do
  @moduledoc """
  Caches the robots.txt files from different hosts in memory.

  Add this module to your supervision tree. Use this module to perform
  fetches of the robots.txt and automatic caching of results. It also
  makes sure the two identical requests don't happen at the same time.
  """

  use GenServer
  alias Gollum.{Parser, Host}
  # State contained in GenServer: Tuple of 3 items
  # 1. data:    %{host => {%Host{}, last_fetch_secs}}
  # 2. pending: %{host => [from_list]}
  # 3. options

  # Default values for options
  @name         Gollum.Cache
  @refresh_secs 86_400
  @lazy_refresh false
  @async        false
  @force        false
  @fetcher      Gollum.Fetcher

  @doc """
  Starts up the cache.

  ## Options

    * `name` - The name of the GenServer. Default value is `Gollum.Cache`.

    * `refresh_secs` - The number of seconds until the robots.txt will be
      refetched from the host. Defaults to `86_400`, which is 1 day.

    * `lazy_refresh` - If this flag is set to `true`, the file will only be
      refetched from the host if needed. Otherwise, the file will be
      refreshed at the interval specified by `refresh_secs`. Defaults to
      `false`.

    * `user_agent` - The user agent to use when performing the GET request. Default
      is `"Gollum"`.
  """
  # Decide not to document `fetcher` option.
  @spec start_link(keyword) :: {:ok, pid} | {:error, term}
  def start_link(opts \\ []) do
    name = opts[:name] || Gollum.Cache
    GenServer.start_link(__MODULE__, {%{}, %{}, opts}, name: name)
  end

  @doc """
  Fetches the robots.txt from a host and stores it in the cache.  
  It will only perform the HTTP request if there isn't any current data in the cache, the
  data is too old (specified in the `refresh_secs` option in `start_link/2`) or when the
  `force` flag is set. This function is useful if you know which hosts you need to request
  beforehand.

  ## Options

    * `name` - The name of the GenServer. Default value is `Gollum.Cache`.

    * `async` - Whether this call is async. If the call is async, `:ok` is always
      returned. The default value is `false`.

    * `force` - If the cache has already fetched from the host, this flag determines
      whether it should force a refresh. Default is `false`.
  """
  @spec fetch(binary, keyword) :: :ok | {:error, term}
  def fetch(host, opts \\ []) when is_binary(host) do
    name  = opts[:name] || @name
    async = opts[:async] || @async

    # Cast if async, else call
    if async do
      GenServer.cast(name, {:fetch, host, opts})
      :ok
    else
      GenServer.call(name, {:fetch, host, opts}, :infinity)
    end
  end

  @doc """
  Gets the `Gollum.Host` struct for the specified host from the cache.

  ## Options

    * `name` - The name of the GenServer. Default value is `Gollum.Cache`.
  """
  @spec get(binary, keyword) :: Gollum.Host.t | nil
  def get(host, opts \\ []) do
    name  = opts[:name] || @name
    GenServer.call(name, {:get, host}, :infinity)
  end

  @doc false
  def handle_info({:fetched, host, {:ok, body}}, {store, pending, opts}) do
    rules = Parser.parse(body)
    host_struct = Host.new(host, rules)
    cur_time = :erlang.system_time(:seconds)

    # Reply :ok to all waiting processes
    Enum.each(pending[host], &GenServer.reply(&1, :ok))

    new_pending = Map.delete(pending, host)
    new_store = Map.put(store, host, {host_struct, cur_time})
    {:noreply, {new_store, new_pending, opts}}
  end
  def handle_info({:fetched, host, {:error, reason}}, {store, pending, opts}) do
    # Reply :error to all waiting processes
    Enum.each(pending[host], &GenServer.reply(&1, {:error, reason}))
    new_pending = Map.delete(pending, host)
    {:noreply, {store, new_pending, opts}}
  end
  def handle_info({:refresh, host}, {store, pending, opts}) do
    GenServer.cast(self(), {:fetch, host, from_refresh: true, async: true})
    Process.send_after(self(), {:refresh, host}, opts[:refresh_secs] * 1_000)
    {:noreply, {store, pending, opts}}
  end

  @doc false
  def handle_call({:fetch, host, fetch_opts}, from, {store, pending, opts}) do
    case pending[host] do
      nil   -> do_possible_fetch({host, [{:from, from} | fetch_opts]}, {store, pending, opts})
      froms -> {:noreply, {store, %{pending | host => [from | froms]}, opts}}
    end
  end
  def handle_call({:get, host}, _from, {store, _pending, _opts} = state) do
    case store[host] do
      nil       -> {:reply, nil, state}
      {data, _} -> {:reply, data, state}
    end
  end

  @doc false
  def handle_cast({:fetch, host, fetch_opts}, {store, pending, opts}) do
    case pending[host] do
      nil    -> do_possible_fetch({host, fetch_opts}, {store, pending, opts})
      _froms -> {:noreply, {store, pending, opts}}
    end
  end

  # Performs the fetch after checking the criteria.
  defp do_possible_fetch({host, fetch_opts}, {store, pending, opts}) do
    cur_time = :erlang.system_time(:seconds)
    with {:force, false}          <- {:force, fetch_opts[:force] || @force},
         {:exists, {_data, time}} <- {:exists, store[host]},
         {:lazy_refresh, true}    <- {:lazy_refresh, opts[:lazy_refresh] || @lazy_refresh},
         refresh_secs             = opts[:refresh_secs] || @refresh_secs,
         {:refresh_secs, true}    <- {:refresh_secs, cur_time - time > refresh_secs}
    do
      do_fetch({host, fetch_opts}, {store, pending, opts})
    else
      {:force, true} -> do_fetch({host, fetch_opts}, {store, pending, opts})
      {:exists, nil} -> do_fetch({host, fetch_opts}, {store, pending, opts})
      {:refresh_secs, false} -> reply_if_sync(fetch_opts, {store, pending, opts})
      {:lazy_refresh, false} ->
        from_refresh = fetch_opts[:from_refresh] || false
        if from_refresh do
          do_fetch({host, fetch_opts}, {store, pending, opts})
        else
          reply_if_sync(fetch_opts, {store, pending, opts})
        end
    end
  end

  # Checks for async and replies appropriately.
  defp reply_if_sync(fetch_opts, state) do
    if fetch_opts[:async] do
      {:noreply, state}
    else
      {:reply, :ok, state}
    end
  end

  # Performs the actual fetch
  defp do_fetch({host, fetch_opts}, {store, pending, opts}) do
    new_pending =
      if fetch_opts[:async] do
        Map.put(pending, host, [])
      else
        Map.put(pending, host, [fetch_opts[:from]])
      end

    # Spawn a background process the fetch so it doesn't block the GenServer
    pid = self()
    # Get the fetcher from the env
    fetcher = opts[:fetcher] || @fetcher
    spawn(fn->
      response = fetcher.fetch(host, Keyword.merge(fetch_opts, opts))
      send(pid, {:fetched, host, response})
    end)

    # Start the non-lazy refresh cycle if opts says so
    from_refresh = fetch_opts[:from_refresh] || false
    lazy_refresh = opts[:lazy_refresh]       || @lazy_refresh
    refresh_secs = opts[:refresh_secs]       || @refresh_secs
    if !from_refresh && !lazy_refresh do
      Process.send_after(self(), {:refresh, host}, refresh_secs * 1_000)
    end

    {:noreply, {store, new_pending, opts}}
  end
end
