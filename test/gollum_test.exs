defmodule GollumTest do
  use ExUnit.Case
  doctest Gollum

  test "greets the world" do
    assert Gollum.hello() == :world
  end
end
