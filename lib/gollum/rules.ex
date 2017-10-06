defmodule Gollum.Rules do
  @moduledoc false

  @doc """
  Stores the ruleset of a single user agent within a certain host's
  robots.txt file.
  """
  @type t :: %Gollum.Rules{
    allowed: list(binary),
    disallowed: list(binary),
    crawl_delay: integer,
  }

  defstruct [
    allowed: [],
    disallowed: [],
    crawl_delay: 0, # in seconds
  ]
end
