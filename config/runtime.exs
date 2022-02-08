import Config

parse_host_and_port = fn
  nil ->
    false
  url ->
    %URI{scheme: scheme, host: host, port: port} = URI.parse(url)
    case scheme do
      "http" ->
        [host: String.to_charlist(host), port: port]
      _ ->
        false
    end
end

################
# 环境变量设置 #
################

# MY_HTTP_PROXY_IP
#
# 当前代理服务器监听的 IP，
# 默认 127.0.0.1。
#
# 示例：
#
#     $ export MY_HTTP_PROXY_IP=0.0.0.0
#
listen_ip =
  System.get_env("MY_HTTP_PROXY_IP", "127.0.0.1")
  |> String.to_charlist()
  |> :inet.parse_address()
  |> case do
    {:ok, ip} -> ip
    {:error, _} -> raise "Invalid value of environment variable $MY_HTTP_PROXY_IP"
  end

# MY_HTTP_PROXY_PORT
#
# 当前代理服务器监听的端口，
# 默认 1080。
#
# 示例：
#
#     $ export MY_HTTP_PROXY_PORT=8888
#
listen_port =
  System.get_env("MY_HTTP_PROXY_PORT", "1080")
  |> String.to_integer()


# MY_HTTP_PROXY_ACCEPTORS
#
# 当前代理服务器 acceptor 数量（暂不支持），
# 默认 1。
#
# 示例：
#
#     $ export MY_HTTP_PROXY_ACCEPTORS=10
#
acceptors =
  System.get_env("MY_HTTP_PROXY_ACCEPTORS", "1")
  |> String.to_integer()

upstream_proxy =
  parse_host_and_port.(System.get_env("HTTP_PROXY") || System.get_env("ALL_PROXY"))

config :my_http_proxy,
  server: [
    ip: listen_ip,
    port: listen_port,
  ],
  tunnels: [
    upstream_proxy: upstream_proxy
  ],
  acceptors: acceptors
