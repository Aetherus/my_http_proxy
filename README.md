# MyHttpProxy

用于演示 HTTP 隧道的代理服务器。

## 代码阅读指南

- 核心模块是 `MyHttpProxy.Server` 和 `MyHttpProxy.Tunnel`
- 阅读代码前建议先了解一下 Erlang 的 gen_tcp 模块，尤其是 active mode 和 controlling process 的关系
- 可以适当了解一下 Erlang 的 inet 模块，不了解也没关系

## TODO

- [ ] 支持代理链
- [ ] 支持多路 accept，从而减少 TCP 握手的堆积
