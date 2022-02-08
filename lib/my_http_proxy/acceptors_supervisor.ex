defmodule MyHttpProxy.AcceptorsSupervisor do
  use Supervisor

  alias MyHttpProxy.Acceptor

  def start_link(acceptors_count) do
    Supervisor.start_link(__MODULE__, acceptors_count, name: __MODULE__)
  end

  @impl true
  def init(acceptors_count) do
    children = Enum.map(1..acceptors_count, fn n ->
      %{
        id: {Acceptor, n},
        start: {Acceptor, :start_link, []},
        type: :worker
      }
    end)
    Supervisor.init(children, strategy: :one_for_one)
  end
end
