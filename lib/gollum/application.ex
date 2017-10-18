defmodule Gollum.Application do
  @moduledoc false

  use Application

  def opts do
    [
      name:         Application.get_env(:gollum, :name),
      refresh_secs: Application.get_env(:gollum, :refresh_secs),
      lazy_refresh: Application.get_env(:gollum, :lazy_refresh),
      user_agent:   Application.get_env(:gollum, :user_agent),
    ]
  end

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      worker(Gollum.Cache, [opts()]),
    ]
    opts = [strategy: :one_for_one, name: Gollum.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
