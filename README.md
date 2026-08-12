# luci-app-frpc-new

[English](README_en.md) | 中文

[![CI](https://github.com/laishouchao/luci-app-frpc-new/actions/workflows/ci.yml/badge.svg)](https://github.com/laishouchao/luci-app-frpc-new/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/laishouchao/luci-app-frpc-new)](https://github.com/laishouchao/luci-app-frpc-new/releases)

基于 frp v0.70.1 完整功能支持的 OpenWrt LuCI 应用。

## 功能特性

- **8 种代理类型**: TCP、UDP、HTTP、HTTPS、STCP、SUDP、XTCP、TCPMux
- **Visitor 客户端**: STCP/XTCP/SUDP 的 Visitor 访问模式
- **10 种插件**: http_proxy、socks5、static_file、unix、stcp、sudp、xtcp、http2https、https2http、https2https、tls2raw
- **TOML 配置格式**: 兼容 frp v0.52.0+ 的 TOML 配置
- **LuCI 界面**: 可视化配置管理，中英文支持
- **CI/CD 自动构建**: 多架构 `.ipk` 包自动发布

## 支持的架构

| 架构 | 包名后缀 |
|------|----------|
| 通用（推荐） | `_all.ipk` |
| x86_64 | `_x86_64.ipk` |
| ARM64 (aarch64) | `_aarch64_generic.ipk` |
| MIPS (mipsel) | `_mipsel_24kc.ipk` |
| ARM Cortex-A7 | `_arm_cortex-a7_neon-vfpv4.ipk` |

## 安装

### 方法一：从 Release 下载

1. 前往 [Releases](https://github.com/laishouchao/luci-app-frpc-new/releases) 页面
2. 下载适合你架构的 `.ipk` 文件
3. 上传到路由器并安装：

```bash
opkg install luci-app-frpc-new_*.ipk
```

### 方法二：从源码编译

```bash
# 在 OpenWrt SDK 目录中
git clone https://github.com/laishouchao/luci-app-frpc-new.git package/luci-app-frpc-new
make menuconfig  # 选择 LuCI -> Applications -> luci-app-frpc-new
make package/luci-app-frpc-new/compile V=s
```

## 依赖

- OpenWrt (18.06+)
- frpc (frp 客户端) 二进制文件

## 快速开始

1. 安装 `luci-app-frpc-new` 包
2. 在路由器上安装 frpc 二进制文件（推荐 v0.70.1）
3. 访问 LuCI 管理界面 → 服务 → Frp 客户端
4. 配置服务器地址和端口
5. 添加代理规则
6. 启动服务

## 配置说明

### 客户端设置

- **服务器地址**: frp 服务器 IP 或域名
- **认证方式**: Token（推荐）或 OIDC
- **TLS**: 启用加密传输（推荐）
- **连接池**: 预建立连接数，提升性能
- **日志级别**: trace/debug/info/warn/error

### 代理设置

- **名称**: 代理规则的唯一标识
- **类型**: 选择适合的代理类型
- **本地 IP/端口**: 需要穿透的本地服务地址
- **远程端口**: 在 frp 服务器上监听的端口
- **自定义域名**: 用于 HTTP/HTTPS 类型的域名绑定

### 高级功能

- **传输设置**: TCP/QUIC/WebSocket/KCP 多种协议
- **负载均衡**: 将流量分发到多个代理
- **健康检查**: 自动检测后端服务可用性
- **元数据**: 自定义键值对，用于服务治理
- **限速**: 单个代理的带宽限制

## frp 版本兼容性

| luci-app-frpc-new 版本 | frp 版本 | 配置格式 |
|------------------------|----------|----------|
| v1.4.0 - v1.5.0 | v0.52.0 - v0.70.1 | TOML |
| v1.0.0 - v1.3.0 | v0.51.0 - v0.52.0 | TOML |

## 许可证

MIT License

## 相关项目

- [frp](https://github.com/fatedier/frp) - 快速反向代理
- [openwrt-wr1200js](https://github.com/laishouchao/openwrt-wr1200js) - OpenWrt 固件
