defmodule MyHttpProxy.ServerSupervisor do
  use Supervisor

  alias MyHttpProxy.{Server, AcceptorsSupervisor}

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    children = [
      {Server, opts[:server] || []},
      {AcceptorsSupervisor, opts[:acceptors] || 1}
    ]
    Supervisor.init(children, strategy: :rest_for_one)
  end
end
