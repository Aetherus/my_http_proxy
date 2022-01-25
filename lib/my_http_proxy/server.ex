defmodule MyHttpProxy.Server do
  require Logger

  use GenServer

  alias MyHttpProxy.{ClientsSupervisor, TunnelsSupervisor, Tunnel}

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
    with {:ok, client_socket} <- :gen_tcp.accept(server_socket, :infinity) do
      Logger.debug("Accepted a client.")
      Task.Supervisor.start_child(ClientsSupervisor, fn -> serve(client_socket) end)
      {:noreply, server_socket, {:continue, :accept}}
    end
  end

  defp listen do
    :gen_tcp.listen(server_port(),
      mode: :binary,
      active: false,
      backlog: 32,
      keepalive: true,
      ip: server_ip(),
      delay_send: false
    )
  end

  defp server_ip, do: {127, 0, 0, 1}
  defp server_port, do: 8888

  defp serve(client_socket) do
    {:ok, binary} = :gen_tcp.recv(client_socket, 0)
    [request_line, _headers_and_body] = String.split(binary, "\r\n", parts: 2)
    Logger.debug(request_line)
    ["CONNECT", target_host_and_port, protocol] = String.split(request_line, ~r/\s/, trim: true)
    [target_host, target_port] = String.split(target_host_and_port, ":", parts: 2)
    target_host = String.to_charlist(target_host)
    target_port = String.to_integer(target_port)
    {:ok, tunnel} = TunnelsSupervisor.start_child(target_host, target_port, client_socket)
    :ok = send_ok_response(client_socket, protocol)
    Tunnel.proxy(tunnel)
  end

  defp send_ok_response(client_socket, protocol) do
    Logger.debug("Sending response to CONNECT request...")
    :gen_tcp.send(client_socket, String.replace("""
    #{protocol} 200 OK
    Connection: close

    """, "\n", "\r\n", global: true))
  end
end
