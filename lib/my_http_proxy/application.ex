defmodule MyHttpProxy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: MyHttpProxy.Worker.start_link(arg)
      # {MyHttpProxy.Worker, arg}
      MyHttpProxy.TunnelsSupervisor,
      {MyHttpProxy.ServerSupervisor, Application.get_all_env(:my_http_proxy)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MyHttpProxy.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
