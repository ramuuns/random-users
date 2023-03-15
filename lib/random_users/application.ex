defmodule RandomUsers.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      RandomUsers.Repo,
      # Start the Telemetry supervisor
      RandomUsersWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: RandomUsers.PubSub},
      # Start the Endpoint (http/https)
      RandomUsersWeb.Endpoint,
      # Start a worker by calling: RandomUsers.Worker.start_link(arg)
      # {RandomUsers.Worker, arg}
      {RandomUsers.MinNumber, name: RandomUsers.MinNumberInstance}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RandomUsers.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RandomUsersWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
