defmodule Gollum do
  @moduledoc """
  Robots.txt parser with caching. Modelled after Kryten (unmaintained library).
  """

  @doc """
  Pre-fetches the data from a host and stores it in the cache. This is useful if
  you know which hosts you need to request beforehand. By default, this executes
  synchronously.
  """
  @spec prefetch(binary | URI.t, keyword) :: :ok | {:error, term}
  def prefetch(host, opts \\ [])
  def prefetch(%URI{host: host}, opts), do: prefetch(host, opts)
  def prefetch(host, opts) when is_binary(host) do
    name = opts[:name] || Gollum
  end
end
