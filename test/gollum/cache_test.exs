defmodule Gollum.CacheTest do
  use ExUnit.Case
  alias Gollum.Cache

  setup do
    Cache.start_link(name: TestCache, fetcher: MockFetcher)
    :ok
  end

  test "cache fetches host data and parses it successfully" do
    assert :ok = Cache.fetch("ok", name: TestCache)
    data = Cache.get("ok", name: TestCache).rules
    assert %{"hello" => %{allowed: ["/hello"], disallowed: ["/hey"]}} = data
  end

  test "cache async fetch works correctly" do
    assert :ok = Cache.fetch("delay_ok", async: true, name: TestCache)
    assert :ok = Cache.fetch("ok", name: TestCache)
    assert Cache.get("ok", name: TestCache)
    refute Cache.get("delay_ok", name: TestCache)
    :timer.sleep(100)
    assert Cache.get("delay_ok", name: TestCache)
  end

  test "cache fetch returns error upon failure" do
    assert {:error, :no_robots_file} = Cache.fetch("error", name: TestCache)
    assert Cache.get("error", name: TestCache) == nil
  end
end
