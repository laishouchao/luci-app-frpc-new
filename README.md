# luci-app-frpc-new

OpenWrt LuCI 应用 — frpc 内网穿透客户端管理界面

基于 frp 官方文档 ([gofrp/frp-doc](https://github.com/gofrp/frp-doc)) 全面支持的 LuCI 管理界面，适用于 frp v0.52.0 ~ v0.70.1+ TOML 配置格式。

## 功能特性

### 支持的代理类型
- **TCP** / **UDP** / **HTTP** / **HTTPS** / **TCPMux** / **STCP** / **XTCP** / **SUDP**

### Visitor 管理
- STCP / XTCP / SUDP 独立访客配置页面
- XTCP NAT 穿透：keepTunnelOpen、fallbackTo（STCP/server）、maxRetries、protocol（quic/kcp/tcp）
- 传输设置：加密、压缩、连接池、带宽限制、传输类型

### 客户端配置
- 服务器连接（地址、端口、客户端用户名、客户端 ID）
- 认证方式（Token / OIDC / Token 文件加载 / 附加认证范围）
- 传输协议（TCP / KCP / QUIC / WebSocket / WSS）
- 线路协议（v1 / v2，v2 支持 AEAD 加密协商）
- TLS 加密、TCP 多路复用、连接池
- 心跳间隔与超时、日志输出目标/级别/保留天数/颜色
- DNS 服务器、STUN 服务器、UDP 包大小
- 登录失败策略、持久化 Store、客户端元数据
- 连接服务器超时/Keepalive/本地IP/代理/TCP Mux 心跳
- TLS 高级配置（证书/密钥/CA/ServerName/首字节）
- QUIC 协议选项（保活/空闲超时/最大流）
- Web 管理面板（地址/端口/用户名/密码/静态资源目录/pprof）

### 实验性功能
- VirtualNet 虚拟网络（Alpha，CIDR 地址配置）
- Feature Gates 功能开关
- 配置文件包含（includes）

### 代理配置
- HTTP 高级设置：Host 头重写、URL 路径路由、自定义请求头/响应头、按用户路由、多路复用器
- STCP/XTCP/SUDP：角色(server/visitor)、密钥、服务名称、允许用户列表
- 健康检查：TCP/HTTP 类型、超时、最大失败次数、间隔、路径、自定义检查头
- 传输设置：加密、压缩、带宽限制、传输类型、代理协议版本
- 负载均衡：分组名、分组密钥
- NAT 穿透：禁用辅助地址（XTCP）
- 插件支持：socks5、http_proxy、static_file、unix_domain_socket、http2socks、sni、http2https、https2http、https2https、tls2raw
- 代理元数据与注解

## 项目结构

```
luci-app-frpc-new/
├── Makefile                    # OpenWrt 包构建定义
├── .github/workflows/
│   ├── ci.yml                  # CI：Lua/Shell 语法检查 + 文件完整性
│   └── release.yml             # 多架构 .ipk 编译 + 自动发布 Release
├── luasrc/
│   ├── controller/frpc.lua     # LuCI 路由和状态 API
│   └── model/cbi/
│       ├── frpc-client.lua     # 主设置页：服务器连接 + 代理列表
│       ├── frpc-proxy.lua      # 代理编辑页：5 个标签页
│       ├── frpc-visitor.lua    # Visitor 编辑页：3 个标签页
│       └── frpc-visitors.lua   # Visitor 列表页
├── root/
│   ├── etc/config/frpc         # UCI 默认配置
│   ├── etc/init.d/frpc         # procd 服务管理脚本
│   └── usr/lib/frpc/
│       └── generate_toml.sh    # UCI → TOML 转换脚本
└── po/zh-cn/frpc.po            # 中文翻译
```

## 安装方法

### 前提条件
- OpenWrt >= 23.05（需要 LuCI）
- frpc 二进制文件（从 [fatedier/frp releases](https://github.com/fatedier/frp/releases) 下载对应架构版本）

### 方法一：从 Release 下载 .ipk（推荐）
1. 从 [Releases](https://github.com/laishouchao/luci-app-frpc-new/releases) 下载对应架构的 `.ipk` 文件
2. 通过 LuCI 界面上传安装：系统 → 软件 → 上传软件包
3. 或命令行安装：`opkg install luci-app-frpc-new_*.ipk`

### 方法二：手动打包
```bash
# 克隆项目
git clone https://github.com/laishouchao/luci-app-frpc-new.git
cd luci-app-frpc-new

# 复制文件到 OpenWrt
scp -r luasrc/* root@192.168.1.1:/usr/lib/lua/luci/
scp root/etc/config/frpc root@192.168.1.1:/etc/config/
scp root/etc/init.d/frpc root@192.168.1.1:/etc/init.d/
scp root/usr/lib/frpc/generate_toml.sh root@192.168.1.1:/usr/lib/frpc/
```

## 架构说明

本包为 `all` 架构（纯 Lua/Shell），所有架构文件内容相同。Release 中提供以下架构版本方便用户选择：

| 架构 | 常见设备 |
|------|----------|
| x86_64 | 虚拟机、x86 软路由 |
| aarch64_generic | 树莓派 4/5、ARM64 路由器 |
| mipsel_24kc | MT7621 路由器（WR1200JS、Newifi 等） |
| arm_cortex-a7 | 树莓派 2/3、ARMv7 路由器 |

## TOML 配置生成

本应用通过 `generate_toml.sh` 脚本将 UCI 配置自动转换为 frpc.toml，生成的配置文件位于 `/etc/frp/frpc.toml`。

支持 pipe (`|`) 分隔的多值字段格式：
- 请求头/响应头：`X-Custom:val1|Authorization:Bearer token`
- URL 路径：`/api|/static`
- 元数据：`Key1:Value1|Key2:Value2`
- 允许用户：`user1,user2`（逗号分隔）

## 开源协议

MIT License
