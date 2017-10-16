defmodule MockFetcher do
  def fetch("ok", _opts) do
    {:ok, "User-agent: Hello\nAllow: /hello\nDisallow: /hey"}
  end
  def fetch("delay_ok", _opts) do
    :timer.sleep(100)
    {:ok, "User-agent: Hello\nAllow: /hello\nDisallow: /hey"}
  end
  def fetch("error", _opts) do
    {:error, :no_robots_file}
  end
  def fetch("http://example.com", _opts) do
    {:ok, "User-agent: Hello\nAllow: /hello\nDisallow: /hey"}
  end
end
