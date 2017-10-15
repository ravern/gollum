defmodule Gollum.CacheTest do
  use ExUnit.Case
  alias Gollum.Cache

  setup do
    Cache.start_link(fetcher: MockFetcher)
    :ok
  end

  test "cache fetches host data and parses it successfully" do
    assert :ok = Cache.fetch("ok")
    data = Cache.get("ok").rules
    assert %{"hello" => %{allowed: ["/hello"], disallowed: ["/hey"]}} = data
  end

  test "cache async fetch works correctly" do
    assert :ok = Cache.fetch("delay_ok", async: true)
    assert :ok = Cache.fetch("ok")
    assert Cache.get("ok")
    refute Cache.get("delay_ok")
    :timer.sleep(100)
    assert Cache.get("delay_ok")
  end

  test "cache fetch returns error upon failure" do
    assert {:error, :no_robots_file} = Cache.fetch("error")
    assert Cache.get("error") == nil
  end
end
