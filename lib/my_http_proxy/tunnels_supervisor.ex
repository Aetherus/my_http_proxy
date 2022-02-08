defmodule MyHttpProxy.TunnelsSupervisor do
  use DynamicSupervisor

  alias MyHttpProxy.Tunnel

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(downstream_socket, tunnel_config) do
    DynamicSupervisor.start_child(__MODULE__, {Tunnel, {downstream_socket, tunnel_config}})
  end
end
