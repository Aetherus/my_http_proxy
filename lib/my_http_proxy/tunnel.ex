defmodule MyHttpProxy.Tunnel do
  require Logger

  use GenServer, restart: :temporary

  defmacrop log(message_template, from_socket, to_socket) do
    quote do
      Logger.debug(fn ->
        with {:ok, {from_ip, from_port}} <- :inet.peername(unquote(from_socket)),
             {:ok, {to_ip, to_port}} <- :inet.peername(unquote(to_socket)) do
          from = "#{:inet.ntoa(from_ip)}:#{from_port}"
          to = "#{:inet.ntoa(to_ip)}:#{to_port}"
          unquote(message_template)
          |> String.replace("$from", from, global: true)
          |> String.replace("$to", to, global: true)
        else
          {:error, :enotconn} -> "Done."
        end
      end)
    end
  end

  def start_link(downstream_socket) do
    GenServer.start_link(__MODULE__, downstream_socket)
  end

  @impl true
  def init(downstream_socket) do
    Process.flag(:trap_exit, true)
    {:ok, downstream_socket, {:continue, :handshake}}
  end

  # 下游和代理握手
  @impl true
  def handle_continue(:handshake, downstream_socket) do
    # 读取整个 HTTP CONNECT 请求，并获取请求行
    {:ok, request} = :gen_tcp.recv(downstream_socket, 0)
    [request_line, _headers_and_body] = String.split(request, "\r\n", parts: 2)
    Logger.debug(request_line)

    # request_line 应是如下字符串：
    # CONNECT www.google.com:443 HTTP/1.1
    {:ok, target_host, target_port, protocol} = parse_request_line(request_line)
    {:ok, upstream_socket} = connect_to_upstream(target_host, target_port)
    log("Tunnel established: $from <~> $to", downstream_socket, upstream_socket)

    # 发送 CONNECT 请求的响应给下游
    :ok = send_handshake_ok_response(downstream_socket, protocol)

    # 把下游 socket 的模式设为 active，
    # 从而可以将它收到的数据包和 socket 关闭事件
    # 转化为消息发给它的 controlling process
    # （在这里是当前 GenServer 进程）
    :inet.setopts(downstream_socket, active: true)

    {:noreply, {downstream_socket, upstream_socket}}
  end

  # 如果上下游的 socket 都关闭了，则销毁隧道
  def handle_continue(:maybe_exit, {nil, nil} = state) do
    Logger.debug("Tunnel is closed.")
    {:stop, :normal, state}
  end

  # 如果上下游的 socket 只要有一个没有关闭，则不销毁隧道
  def handle_continue(:maybe_exit, state) do
    {:noreply, state}
  end

  @impl true

  # 把下游发过来的 TCP 包原样发给上游
  def handle_info({:tcp, downstream_socket, data}, {downstream_socket, upstream_socket} = state) do
    if upstream_socket do
      log("Sending #{byte_size(data)} bytes: $from -> $to", downstream_socket, upstream_socket)
      :ok = :gen_tcp.send(upstream_socket, data)
    end
    {:noreply, state}
  end

  # 把上游发过来的 TCP 包原样发给下游
  def handle_info({:tcp, upstream_socket, data}, {downstream_socket, upstream_socket} = state) do
    if downstream_socket do
      log("Sending #{byte_size(data)} bytes: $from -> $to", upstream_socket, downstream_socket)
      :ok = :gen_tcp.send(downstream_socket, data)
    end
    {:noreply, state}
  end

  # 下游 TCP socket 关闭
  def handle_info({:tcp_closed, downstream_socket}, {downstream_socket, upstream_socket}) do
    Logger.debug("Downstream socket is closed.")
    {:noreply, {nil, upstream_socket}, {:continue, :maybe_exit}}
  end

  # 上游 TCP socket 关闭
  def handle_info({:tcp_closed, upstream_socket}, {downstream_socket, upstream_socket}) do
    Logger.debug("Upstream socket is closed.")
    {:noreply, {downstream_socket, nil}, {:continue, :maybe_exit}}
  end

  def handle_info(_, state), do: state

  @impl true
  def terminate(_reason, {downstream_socket, upstream_socket}) do
    downstream_socket && :gen_tcp.shutdown(downstream_socket, :read_write)
    upstream_socket && :gen_tcp.shutdown(upstream_socket, :read_write)
  end

  defp parse_request_line(request_line) do
    ["CONNECT", target_host_and_port, protocol] = String.split(request_line, ~r/\s/, trim: true)
    [target_host, target_port] = String.split(target_host_and_port, ":", parts: 2)
    target_host = String.to_charlist(target_host)
    target_port = String.to_integer(target_port)
    {:ok, target_host, target_port, protocol}
  end

  defp connect_to_upstream(target_host, target_port) do
    # TODO: 如果代理服务器本身配置了 HTTP 代理，则连接上游 HTTP 代理，否则连接目标服务器
    :gen_tcp.connect(target_host, target_port, active: true, mode: :binary, keepalive: true)
  end

  defp send_handshake_ok_response(downstream_socket, protocol) do
    Logger.debug("Sending response to CONNECT request ...")
    :ok = :gen_tcp.send(downstream_socket, build_handshake_ok_response(protocol))
  end

  defp build_handshake_ok_response(protocol) do
    # 根据 RFC-7231 规定，
    # CONNECT 请求的成功响应
    # 不能携带 Content-Length
    # 和 Transfer-Encoding 响应头！
    """
    #{protocol} 200 OK
    Connection: close

    """
    |> String.replace("\n", "\r\n", global: true)
  end
end
