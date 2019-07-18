defmodule RePG2.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(RePG2.Worker, [])
    ]

    opts = [strategy: :one_for_one, name: RePG2.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
