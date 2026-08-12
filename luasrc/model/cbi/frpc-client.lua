local m, s, o

m = Map("frpc", translate("frpc - Client Settings"),
	translate("Configure frpc client for frp >= 0.52.0 (TOML-based). " ..
		"UCI config is the source of truth; TOML is generated automatically on save."))

-- ============================================================
-- Section: Server Settings (singleton named section)
-- ============================================================
s = m:section(NamedSection, "main", "frpc", translate("Server Settings"))
s.addremove = false
s.anonymous = true

-- Status display (read-only, rendered via JS)
o = s:option(DummyValue, "_status", translate("Running Status"))
o.template = "frpc/status_display"
o.value = translate("Collecting...")

o = s:option(Flag, "enabled", translate("Enable frpc"))
o.default = "0"
o.rmempty = false

o = s:option(Value, "server_addr", translate("Server Address"),
	translate("IP address or hostname of the frps server"))
o.datatype = "host"
o.placeholder = "0.0.0.0"
o.rmempty = false

o = s:option(Value, "server_port", translate("Server Port"),
	translate("Port of the frps server"))
o.datatype = "port"
o.default = "7000"
o.rmempty = false

o = s:option(Value, "token", translate("Authentication Token"),
	translate("Password for authentication with the frps server. " ..
		"Must match the token configured on frps."))
o.password = true
o.rmempty = true

o = s:option(Flag, "tls", translate("Enable TLS"))
o.default = "1"
o.rmempty = false

o = s:option(Value, "server_name", translate("TLS Server Name"),
	translate("Server name for TLS SNI. Leave empty to use server address."))
o.datatype = "hostname"
o.rmempty = true
o:depends("tls", "1")

-- ============================================================
-- Section: Proxy List (TypedSection - table view)
-- ============================================================
s = m:section(TypedSection, "proxy", translate("Proxy List"),
	translate("Add proxy rules to expose local services through the frp server."))
s.template = "cbi/tblsection"
s.addremove = true
s.anonymous = true
s.sortable = true
s.extedit = luci.dispatcher.build_url("admin", "services", "frpc", "client", "proxy", "%s")
s.create_url = luci.dispatcher.build_url("admin", "services", "frpc", "client", "proxy", "new")

o = s:option(Flag, "enabled", translate("Enable"))
o.default = "1"
o.rmempty = false
o.width = "5%"

o = s:option(Value, "name", translate("Proxy Name"))
o.rmempty = false
o.width = "12%"

o = s:option(ListValue, "type", translate("Type"))
o:value("tcp", "TCP")
o:value("udp", "UDP")
o:value("http", "HTTP")
o:value("https", "HTTPS")
o:value("stcp", "STCP")
o:value("xtcp", "XTCP")
o:value("sudp", "SUDP")
o.default = "tcp"
o.rmempty = false
o.width = "8%"

o = s:option(Value, "local_ip", translate("Local IP"))
o.datatype = "ipaddr"
o.placeholder = "127.0.0.1"
o.default = "127.0.0.1"
o.rmempty = false
o.width = "12%"

o = s:option(Value, "local_port", translate("Local Port"))
o.datatype = "port"
o.rmempty = false
o.width = "8%"

o = s:option(Value, "remote_port", translate("Remote Port"))
o.datatype = "port"
o.rmempty = true
o.width = "8%"

o = s:option(ListValue, "plugin_type", translate("Plugin"))
o:value("", translate("None"))
o:value("socks5", "socks5")
o:value("http_proxy", "http_proxy")
o:value("static_file", "static_file")
o:value("unix_domain_socket", "unix_domain_socket")
o:value("http2socks", "http2socks")
o:value("sni", "sni")
o.rmempty = true
o.width = "10%"

o = s:option(Value, "plugin_user", translate("Plugin User"))
o.rmempty = true
o.width = "10%"

o = s:option(Value, "plugin_pass", translate("Plugin Password"))
o.password = true
o.rmempty = true
o.width = "10%"

m.on_after_commit = function(self)
	luci.util.exec("/etc/init.d/frpc restart >/dev/null 2>&1 &")
end

return m
