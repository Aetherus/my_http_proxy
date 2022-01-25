defmodule MyHttpProxy.Tunnel do
  require Logger

  use GenServer, restart: :temporary

  @timeout 50

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

  def start_link({target_host, target_port, client_socket}) do
    GenServer.start_link(__MODULE__, {target_host, target_port, client_socket})
  end

  def proxy(tunnel) do
    GenServer.cast(tunnel, :proxy)
  end

  @impl true
  def init({target_host, target_port, client_socket}) do
    Process.flag(:trap_exit, true)
    with {:ok, tunnel_socket} <- :gen_tcp.connect(target_host, target_port, [active: false, mode: :binary, keepalive: true], 60_000) do
      {:ok, {client_socket, tunnel_socket}}
    end
  end

  @impl true
  def handle_cast(:proxy, {client_socket, tunnel_socket} = state) do
    tunnel(client_socket, tunnel_socket, state)
  end

  defp tunnel(from_socket, to_socket, state) do
    log("$from -> $to", from_socket, to_socket)

    with {:ok, data} <- :gen_tcp.recv(from_socket, 0, @timeout),
         :ok <- :gen_tcp.send(to_socket, data) do
      tunnel(from_socket, to_socket, state)
    else
      {:error, :timeout} ->
        log("$from timed out.", from_socket, to_socket)
        tunnel(to_socket, from_socket, state)
      {:error, :closed} ->
        log("$from closed.", from_socket, to_socket)
        {:stop, :normal, state}
      error ->
        Logger.error(inspect error)
        {:stop, error, state}
    end
  end

  @impl true
  def terminate(_reason, {client_socket, tunnel_socket}) do
    :gen_tcp.shutdown(client_socket, :read_write)
    :gen_tcp.shutdown(tunnel_socket, :read_write)
  end
end
