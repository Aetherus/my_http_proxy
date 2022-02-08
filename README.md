# MyHttpProxy

用于演示 HTTP 隧道的代理服务器。

## 环境变量

### MY_HTTP_PROXY_IP

当前代理服务器监听的 IP，默认 127.0.0.1。
如果设为 0.0.0.0，则表示监听本机的所有网络适配器。

### MY_HTTP_PROXY_PORT

当前代理服务器监听的端口，默认 1080。

## 上游代理设置

本代理服务器只支持 HTTP 代理作为上游代理。
支持常见的环境变量 `HTTP_PROXY` 和 `ALL_PROXY`。 

## 代码阅读指南

- 核心模块是 `MyHttpProxy.Server` 和 `MyHttpProxy.Tunnel`
- 阅读代码前建议先了解一下 Erlang 的 gen_tcp 模块，尤其是 active mode 和 controlling process 的关系
- 可以适当了解一下 Erlang 的 inet 模块，不了解也没关系

## TODO

- [x] 支持监听 IP、端口配置
- [x] 支持代理链
- [x] 支持多路 accept，从而减少 TCP 握手的堆积
- [ ] 支持 basic authorization
- [ ] 支持白名单
