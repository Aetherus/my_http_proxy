defmodule MyHttpProxy.AcceptorsSupervisor do
  use Supervisor

  alias MyHttpProxy.Acceptor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    acceptors_count = opts[:count] || 10
    upstream_proxy = opts[:upstream_proxy]
    children = Enum.map(1..acceptors_count, fn n ->
      %{
        id: {Acceptor, n},
        start: {Acceptor, :start_link, [upstream_proxy]},
        type: :worker
      }
    end)
    Supervisor.init(children, strategy: :one_for_one)
  end
end
