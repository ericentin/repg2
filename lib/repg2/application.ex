defmodule RePG2.Application do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(RePG2.Worker, []),
    ]

    opts = [strategy: :one_for_one, name: RePG2.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
