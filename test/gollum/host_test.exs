defmodule Gollum.HostTest do
  use ExUnit.Case, async: true
  alias Gollum.Host
  doctest Gollum.Host

  test "which_agent/2" do
    agents = ~w(googlebot-news * googlebot)
    assert Host.which_agent("Googlebot-News", agents) == "googlebot-news"
    assert Host.which_agent("Googlebot", agents) == "googlebot"
    assert Host.which_agent("Googlebot-Image", agents) == "googlebot"
    assert Host.which_agent("Otherbot", agents) == "*"
  end

  test "match_agent?/2" do
    assert Host.match_agent?("Hello", "He")
    refute Host.match_agent?("Hello", "Helloo")
  end

  test "match_path?/2" do
    assert Host.match_path?("/anyValidURL", "/")
    assert Host.match_path?("/anyValidURL", "/*")
    assert Host.match_path?("/fish.html", "/fish")
    assert Host.match_path?("/fish/salmon.html", "/fish*")
    assert Host.match_path?("/fish/", "/fish/")
    assert Host.match_path?("/filename.php", "/*.php")
    assert Host.match_path?("/folder/filename.php", "/*.php$")
    assert Host.match_path?("/fishheads/catfish.php?parameters", "/fish*.php")
    refute Host.match_path?("/fish", "/fish/")
    refute Host.match_path?("/", "/*.php")
    refute Host.match_path?("/filename.php?params", "/*.php$")
    refute Host.match_path?("/Fish.PHP", "/fish*.php")
    refute Host.match_path?("/Fish.asp", "/fish")
    refute Host.match_path?("/catfish", "/fish*")
  end
end
