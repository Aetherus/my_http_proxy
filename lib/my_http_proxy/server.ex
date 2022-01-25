defmodule MyHttpProxy.Server do
  require Logger

  use GenServer

  alias MyHttpProxy.TunnelsSupervisor

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    ip = opts[:ip] || {0, 0, 0, 0}
    port = opts[:port] || 1080
    with {:ok, server_socket} <- listen(ip, port) do
      Logger.debug("HTTP Proxy server is listening on #{:inet.ntoa(ip)}:#{port}.")
      {:ok, server_socket, {:continue, {:accept, opts}}}
    end
  end

  @impl true
  def handle_continue({:accept, opts}, server_socket) do
    with {:ok, downstream_socket} <- :gen_tcp.accept(server_socket, :infinity),
         {:ok, tunnel} <- TunnelsSupervisor.start_child(downstream_socket, opts[:upstream_proxy]),
         :ok <- :gen_tcp.controlling_process(downstream_socket, tunnel),
         do: {:noreply, server_socket, {:continue, {:accept, opts}}}
  end

  defp listen(ip, port) do
    :gen_tcp.listen(port,
      mode: :binary,
      active: false,
      backlog: 32,
      keepalive: true,
      ip: ip
    )
  end
end
