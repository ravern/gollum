defmodule Gollum.Matcher do
  @moduledoc """
  Contain many utility functions used in the other modules.
  """

  @doc """
  Returns the most suitable user agent string from the specified list,
  based on the specified user agent string. If none are found, returns
  nil. Checks are case insensitive.

  This check is based on [this spec](https://developers.google.com/search/reference/robots_txt#order-of-precedence-for-user-agents)

  ## Examples

      iex> alias Gollum.Matcher
      iex> agents = ~w(googlebot-news * googlebot)
      iex> Matcher.which_agent("Googlebot-News", agents)
      "googlebot-news"
      iex> Matcher.which_agent("Googlebot", agents)
      "googlebot"
      iex> Matcher.which_agent("Googlebot-Image", agents)
      "googlebot"
      iex> Matcher.which_agent("Otherbot", agents)
      "*"
  """
  @spec which_agent(binary, list(binary)) :: binary | nil
  def which_agent(agent, agents) when is_binary(agent) do
    agent = String.downcase(agent)
    agents
    |> Enum.map(&String.downcase/1)
    |> Enum.filter(&match_agent?(agent, &1))
    |> Enum.max_by(&String.length/1)
  end

  @doc """
  Returns whether the user agent string on the left matches the user
  agent string on the right.

  This check is based on [this spec](https://developers.google.com/search/reference/robots_txt#order-of-precedence-for-user-agents).

  ## Examples

      iex> alias Gollum.Matcher
      iex> Matcher.match_agent?("Hello", "He")
      true
      iex> Matcher.match_agent?("Hello", "Helloo")
      false
  """
  @spec match_agent?(binary, binary) :: true | false
  def match_agent?(lhs, rhs) when is_binary(lhs) and is_binary(rhs) do
    String.starts_with?(lhs, rhs) || rhs == "*"
  end
end
