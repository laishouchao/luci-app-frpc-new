# luci-app-frpc-new

OpenWrt LuCI 应用 — frpc 内网穿透客户端管理界面

基于 frp 官方文档 ([gofrp/frp-doc](https://github.com/gofrp/frp-doc)) 全面支持的 LuCI 管理界面，兼容 frp v0.52.0 ~ v0.70.1+ TOML 配置格式。

## 功能特性

### 支持的代理类型
- **TCP** / **UDP** / **HTTP** / **HTTPS** / **TCPMux** / **STCP** / **XTCP** / **SUDP**

### Visitor 访客配置
- STCP / XTCP / SUDP 访客端支持
- XTCP NAT 穿透：keepTunnelOpen、fallbackTo（STCP/server）、maxRetries、protocol(quic/kcp/tcp)
- 传输设置：加密、压缩、带宽限制、连接池

### 客户端配置
- 服务器连接（地址、端口、客户端用户名、客户端 ID）
- 认证方式（Token / OIDC / Token 文件加载）
- 传输协议（TCP / KCP / QUIC / WebSocket / WSS）
- 线路协议（v1 / v2，v2 支持 AEAD 加密协商）
- TLS 加密、TCP 多路复用、连接池
- 心跳间隔与超时、日志级别与保留天数
- DNS 服务器、STUN 服务器、UDP 包大小
- 登录失败策略、持久化 Store、客户端元数据

### 代理配置
- HTTP 高级设置：Host 头重写、URL 路径路由、自定义请求头/响应头、按用户路由、多路复用器
- STCP/XTCP/SUDP：角色(server/visitor)、密钥、服务名称、允许用户列表
- XTCP NAT 穿透：禁用辅助地址（仅使用 STUN 发现的公网地址）
- 健康检查：TCP/HTTP 类型、超时、最大失败次数、间隔、路径、自定义检查头
- 传输设置：加密、压缩、带宽限制、传输类型、代理协议版本
- 负载均衡：分组名称、分组密钥
- 插件支持：socks5、http_proxy、static_file、unix_domain_socket、http2socks、sni
- 代理元数据、代理注释

## 项目结构

```
luci-app-frpc-new/
├── Makefile                    # OpenWrt 包构建定义
├── luasrc/
│   ├── controller/frpc.lua     # LuCI 路由和状态 API
│   └── model/cbi/
│       ├── frpc-client.lua     # 主设置页：服务器连接 + 代理列表
│       ├── frpc-proxy.lua      # 代理编辑页：5 个标签页
│       ├── frpc-visitors.lua   # 访客列表页
│       └── frpc-visitor.lua    # 访客编辑页：3 个标签页
├── root/
│   ├── etc/config/frpc         # UCI 默认配置
│   ├── etc/init.d/frpc         # procd 服务管理脚本
│   └── usr/lib/frpc/
│       └── generate_toml.sh    # UCI → TOML 转换脚本
└── po/zh-cn/frpc.po            # 中文翻译
```

## 安装方法

### 前提条件
- OpenWrt >= 21.02（需要 LuCI）
- frpc 二进制文件（从 [fatedier/frp releases](https://github.com/fatedier/frp/releases) 下载对应架构版本）

### 安装步骤
1. 下载 Release 中的 `.ipk` 文件
2. 上传到路由器并安装：`opkg install luci-app-frpc-new_*.ipk`
3. 访问 LuCI → 服务 → frpc 进行配置

## TOML 配置生成

本应用通过 `generate_toml.sh` 脚本将 UCI 配置自动转换为 frpc.toml，生成的配置文件位于 `/etc/frp/frpc.toml`。

支持 pipe (`|`) 分隔的多值字段格式：
- 请求头/响应头：`X-Custom:val1|Authorization:Bearer token`
- URL 路径：`/api|/static`
- 元数据：`Key1:Value1|Key2:Value2`
- 允许用户：`user1,user2`（逗号分隔）

## 开源协议

MIT License
