defmodule AssetPlayground.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      AssetPlaygroundWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: AssetPlayground.PubSub},
      # Start the Endpoint (http/https)
      AssetPlaygroundWeb.Endpoint
      # Start a worker by calling: AssetPlayground.Worker.start_link(arg)
      # {AssetPlayground.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AssetPlayground.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    AssetPlaygroundWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
