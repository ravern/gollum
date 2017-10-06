defmodule Gollum.HostTest do
  use ExUnit.Case, async: true
  alias Gollum.Host
  doctest Gollum.Host

  test "which_agent/1" do
    agents = ~w(googlebot-news * googlebot)
    assert Host.which_agent("Googlebot-News", agents) == "googlebot-news"
    assert Host.which_agent("Googlebot", agents) == "googlebot"
    assert Host.which_agent("Googlebot-Image", agents) == "googlebot"
    assert Host.which_agent("Otherbot", agents) == "*"
  end

  test "match_agent?/1" do
    assert Host.match_agent?("Hello", "He") == true
    assert Host.match_agent?("Hello", "Helloo") == false
  end
end
