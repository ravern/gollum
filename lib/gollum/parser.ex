defmodule Gollum.Parser do
  @moduledoc """
  Parses a robots.txt file.
  """

  @doc """
  Parse the file, passed in as a simple binary.

  It follows the [spec defined by Google](https://developers.google.com/search/reference/robots_txt)
  as closely as possible.

  ## Examples
  ```
  iex> alias Gollum.Parser
  iex> Parser.parse("User-agent: Hello\\nAllow: /hello\\nDisallow: /hey")
  %{"hello" => %{allowed: ["/hello"], disallowed: ["/hey"]}}
  ```
  """
  @spec parse(binary) :: map
  def parse(string) do
    tokens =
      string
      |> String.split("\n")
      |> Stream.map(&String.trim/1)
      |> Stream.filter(&(!String.starts_with?(&1, "#")))
      |> Stream.map(&tokenize/1)
      |> Stream.filter(&(&1 != :unknown))
      |> Enum.to_list()

    # Perform the parsing with recursion
    do_parse(tokens, {[], nil}, %{})
  end

  # Tokenize a single line of the robots.txt.
  defp tokenize(line) do
    cond do
      result = Regex.run(~r/^allow:?\s(.+)$/i,      line) -> {:allow,      Enum.at(result, 1)}
      result = Regex.run(~r/^disallow:?\s(.+)$/i,   line) -> {:disallow,   Enum.at(result, 1)}
      result = Regex.run(~r/^user-agent:?\s(.+)$/i, line) -> {:user_agent, Enum.at(result, 1)}
      true -> :unknown
    end
  end

  # Does the actual parsing. Params are:
  # 1. List of tokens remaining
  # 2. Tuple of {[user_agents], rules_accum} as the buffer
  # 3. Accumulator
  # Haven't started parsing rules, add to list of agents (downcase when adding)
  defp do_parse([{:user_agent, agent} | tokens], {agents, nil}, accum) do
    do_parse(tokens, {[String.downcase(agent) | agents], nil}, accum)
  end
  # Finished parsing a set of rules, add rules to accum and reset rules to nil
  defp do_parse([{:user_agent, agent} | tokens], {agents, rules}, accum) do
    accum = Enum.reduce(agents, accum, &Map.put(&2, &1, rules))
    do_parse(tokens, {[agent], nil}, accum)
  end
  # Add an allowed field
  defp do_parse([{:allow, path} | tokens], {agents, rules}, accum) do
    rules = Map.put(rules || %{}, :allowed, [path | rules[:allowed] || []])
    do_parse(tokens, {agents, rules}, accum)
  end
  # Add a disallowed field
  defp do_parse([{:disallow, path} | tokens], {agents, rules}, accum) do
    rules = Map.put(rules || %{}, :disallowed, [path | rules[:disallowed] || []])
    do_parse(tokens, {agents, rules}, accum)
  end
  # End the parsing, current buffer has nothing, so just return the accumulator
  defp do_parse([], {_agents, nil}, accum) do
    accum
  end
  # End the parsing, and add the current buffer to the accumulator
  defp do_parse([], {agents, rules}, accum) do
    Enum.reduce(agents, accum, &Map.put(&2, &1, rules))
  end
end
