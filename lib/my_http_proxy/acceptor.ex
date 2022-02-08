defmodule MyHttpProxy.Acceptor do
  use GenServer, shutdown: :brutal_kill

  alias MyHttpProxy.{Server, TunnelsSupervisor}

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  @impl true
  def init(_) do
    {:ok, [], {:continue, :accept}}
  end

  @impl true
  def handle_continue(:accept, _) do
    with server_socket <- Server.get_socket(),
         {:ok, downstream_socket} <- :gen_tcp.accept(server_socket, :infinity),
         {:ok, tunnel} <- TunnelsSupervisor.start_child(downstream_socket, tunnel_config()),
         :ok <- :gen_tcp.controlling_process(downstream_socket, tunnel),
         do: {:noreply, server_socket, {:continue, :accept}}
  end

  defp tunnel_config do
    Application.get_env(:my_http_proxy, :tunnels)
  end
end
