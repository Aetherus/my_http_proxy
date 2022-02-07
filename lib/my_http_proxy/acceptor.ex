defmodule MyHttpProxy.Acceptor do
  use GenServer, shutdown: :brutal_kill

  alias MyHttpProxy.{Server, TunnelsSupervisor}

  def start_link(upstream_proxy) do
    GenServer.start_link(__MODULE__, upstream_proxy)
  end

  @impl true
  def init(upstream_proxy) do
    {:ok, upstream_proxy, {:continue, :accept}}
  end

  @impl true
  def handle_continue(:accept, upstream_proxy) do
    with server_socket <- Server.get_socket(),
         {:ok, downstream_socket} <- :gen_tcp.accept(server_socket, :infinity),
         {:ok, tunnel} <- TunnelsSupervisor.start_child(downstream_socket, upstream_proxy),
         :ok <- :gen_tcp.controlling_process(downstream_socket, tunnel),
         do: {:noreply, server_socket, {:continue, :accept}}
  end
end
