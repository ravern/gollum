defmodule Gollum.Host do
  @moduledoc """
  Represents one host's robots.txt files.
  """

  # Its just a small wrapper.
  @type t :: %Gollum.Host{host: binary, rules: map}
  @enforce_keys [:host, :rules]
  defstruct host: "", rules: %{}

  @doc false
  def lol do
  end

  @doc """
  Creates a new `Gollum.Host` struct, passing in the host and rules.
  The rules usually are the output of the parser.

  ## Examples

      iex> alias Gollum.Host
      iex> rules = %{"Hello" => %{allowed: [], disallowed: []}}
      iex> Host.new("hello.net", rules)
      %Gollum.Host{host: "hello.net", rules: %{"Hello" => %{allowed: [], disallowed: []}}}
  """
  @spec new(binary, map) :: Gollum.Host.t
  def new(host, rules) do
    %Gollum.Host{host: host, rules: rules}
  end

  @doc """
  Returns whether a specified path is crawlable by the specified user agent,
  based on the rules defined in the specified host struct.

  Checks are done based on the specification defined by Google, which can be
  found [here](https://developers.google.com/search/reference/robots_txt).

  ## Examples

      iex> alias Gollum.Host
      iex> rules = %{
      ...>   "Hello" => %{
      ...>     allowed: ["/p"],
      ...>     disallowed: ["/"],
      ...>   },
      ...>   "OtherHello" => %{
      ...>     allowed: ["/$"],
      ...>     disallowed: ["/"],
      ...>   },
      ...>   "*" => %{
      ...>     allowed: ["/page"],
      ...>     disallowed: ["/*.htm"],
      ...>   },
      ...> }
      iex> host = Host.new("hello.net", rules)
      iex> Host.crawlable?(host, "Hello", "/page")
      :crawlable
      iex> Host.crawlable?(host, "OtherHello", "/page.htm")
      :uncrawlable
      iex> Host.crawlable?(host, "NotHello", "/page.htm")
      :undefined
  """
  @spec crawlable?(Gollum.Host.t, binary, binary) :: :crawlable | :uncrawlable | :undefined
  def crawlable?(%Gollum.Host{rules: rules}, user_agent, path) do
  end

  @doc false
  # Returns the most suitable user agent string from the specified list, based
  # on the specified user agent string. If none are found, returns nil. Checks
  # are case insensitive.
  def which_agent(agent, agents) when is_binary(agent) do
    agent = String.downcase(agent)
    agents
    |> Enum.map(&String.downcase/1)
    |> Enum.filter(&match_agent?(agent, &1))
    |> Enum.max_by(&String.length/1)
  end

  @doc false
  # Returns whether the user agent string on the left matches the user agent
  # string on the right.
  def match_agent?(lhs, rhs) do
    String.starts_with?(lhs, rhs) || rhs == "*"
  end
end
