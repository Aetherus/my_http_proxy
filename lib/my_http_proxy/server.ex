defmodule MyHttpProxy.Server do
  require Logger

  use GenServer

  alias MyHttpProxy.TunnelsSupervisor

  def start_link(_) do
    GenServer.start_link(__MODULE__, [])
  end

  @impl true
  def init(_) do
    with {:ok, server_socket} = listen() do
      Logger.debug("HTTP Proxy server is listening on #{:inet.ntoa server_ip()}:#{server_port()}.")
      {:ok, server_socket, {:continue, :accept}}
    end
  end

  @impl true
  def handle_continue(:accept, server_socket) do
    with {:ok, downstream_socket} <- :gen_tcp.accept(server_socket, :infinity),
         {:ok, tunnel} <- TunnelsSupervisor.start_child(downstream_socket),
         :ok <- :gen_tcp.controlling_process(downstream_socket, tunnel),
         do: {:noreply, server_socket, {:continue, :accept}}
  end

  defp listen do
    :gen_tcp.listen(server_port(),
      mode: :binary,
      active: false,
      backlog: 32,
      keepalive: true,
      ip: server_ip()
    )
  end

  defp server_ip, do: {127, 0, 0, 1}
  defp server_port, do: 8888
end
