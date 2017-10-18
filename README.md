[![Build Status](https://semaphoreci.com/api/v1/ravernkoh/gollum/branches/master/shields_badge.svg)](https://semaphoreci.com/ravernkoh/gollum)

# Gollum
Robots.txt parser with caching. Modelled after Kryten. Docs can be found [here](https://hexdocs.pm/gollum/api-reference.html).

# Usage
Call Gollum.crawlable?/3 to obtain whether a certain URL is permitted for the specified user agent.
```elixir
iex> Gollum.crawlable?("hello", "https://google.com/")
:crawlable
iex> Gollum.crawlable?("hello", "https://google.com/m/")
:uncrawlable
```

Gollum is an OTP app (For the cache) so just remember to specify it in the extra_applications key in your mix.exs to ensure it is started.

Gollum allows for some configuration in your config.exs file. The following shows their default values. They are all optional.
```elixir
config :gollum,
  name: Gollum.Cache, # Name of the Cache GenServer
  refresh_secs: 86_400, # Amount of time before the robots.txt will be refetched
  lazy_refresh: false, # Whether to setup a timer that auto-refetches, or to only refetch when requested
  user_agent: "Gollum" # User agent to use when sending the GET request for the robots.txt
```

# Author
Ravern Koh - <<ravern.koh.dev@gmail.com>>
