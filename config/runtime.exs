import Config

config :my_http_proxy,
  ip: {0, 0, 0, 0},
  port: 8888,
  acceptors: 4,
  # upstream_proxy: [host: '127.0.0.1', port: 8889]
  upstream_proxy: false
