include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-frpc-new
PKG_VERSION:=1.0.0
PKG_RELEASE:=1

PKG_MAINTAINER:=frpc-new

LUCI_TITLE:=LuCI app for frpc (TOML-based v0.69.1)
LUCI_DESCRIPTION:=Provides a web interface for configuring frpc client with TOML-based configuration format (frp >= 0.52.0).
LUCI_DEPENDS:=+frpc
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
