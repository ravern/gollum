defmodule Gollum.Cache do
  @moduledoc """
  Caches the robots.txt files from different hosts in memory.

  Add this module to your supervision tree. Call this module to perform
  pre-fetches, and makes sure the requests don't get repeated.
  """

  use GenServer

  @doc """
  Starts up the cache.

  ## Options

    * `name` - The name of the GenServer. Default value is `Gollum.Cache`.
  """
  def start_link(opts \\ []) do
    name = opts[:name] || Gollum
    GenServer.start_link(__MODULE__, {%{}, %{}}, name: name)
  end
end
