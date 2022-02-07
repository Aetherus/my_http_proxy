defmodule MyHttpProxy.Server do
  require Logger

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_socket do
    GenServer.call(__MODULE__, :get_socket)
  end

  @impl true
  def init(opts) do
    ip = opts[:ip] || {127, 0, 0, 1}
    port = opts[:port] || 1080
    with {:ok, server_socket} <- listen(ip, port) do
      Logger.debug("HTTP Proxy server is listening on #{:inet.ntoa(ip)}:#{port}.")
      {:ok, server_socket}
    end
  end

  @impl true
  def handle_call(:get_socket, _from, server_socket) do
    {:reply, server_socket, server_socket}
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
