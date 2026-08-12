-- frpc-client.lua: Main settings page for frpc client
-- This model defines the client common configuration and the proxy list section.
-- It is the primary page under Services → frpc → Settings.

local m, s, o

-- ================================================================
-- Map: frpc client common settings
-- ================================================================
m = Map("frpc", translate("frpc Client Settings"),
	translate("Configuration for the frpc client and its proxy list."))

-- ================================================================
-- Section: Server Connection
-- ================================================================
s = m:section(NamedSection, "main", "frpc", translate("Server Connection"))

o = s:option(Value, "server_addr", translate("Server Address"))
o.datatype = "host"
o.rmempty = false

o = s:option(Value, "server_port", translate("Server Port"))
o.datatype = "port"
o.placeholder = "7000"
o.default = "7000"
o.rmempty = false

-- ================================================================
-- Section: Authentication
-- ================================================================
s = m:section(NamedSection, "main", "frpc", translate("Authentication"))

o = s:option(ListValue, "auth_type", translate("Authentication Method"))
o:value("token", "Token")
o.default = "token"
o.rmempty = false

o = s:option(Value, "auth_token", translate("Token"))
o.password = true
o.rmempty = false
o:depends("auth_type", "token")

-- ================================================================
-- Section: Transport
-- ================================================================
s = m:section(NamedSection, "main", "frpc", translate("Transport"))

o = s:option(ListValue, "transport_protocol", translate("Protocol"),
	translate("Communication protocol between frpc and frps"))
o:value("tcp", "TCP")
o:value("kcp", "KCP")
o:value("quic", "QUIC")
o:value("wss", "WebSocket TLS (wss)")
o.default = "tcp"
o.rmempty = true

o = s:option(Flag, "tls", translate("TLS"),
	translate("Enable TLS encryption for the connection"))
o.default = "0"
o.rmempty = false

o = s:option(Flag, "tcp_mux", translate("TCP Mux"),
	translate("Enable TCP multiplexing for connection reuse"))
o.default = "0"
o.rmempty = false

o = s:option(Value, "pool_count", translate("Connection Pool"),
	translate("Number of connections to keep in connection pool"))
o.datatype = "uinteger"
o.placeholder = "1"
o.rmempty = true

o = s:option(Value, "heartbeat_interval", translate("Heartbeat Interval"),
	translate("Interval for sending heartbeat to server (seconds)"))
o.datatype = "uinteger"
o.placeholder = "30"
o.rmempty = true

o = s:option(Value, "heartbeat_timeout", translate("Heartbeat Timeout"),
	translate("Timeout for heartbeat response (seconds)"))
o.datatype = "uinteger"
o.placeholder = "90"
o.rmempty = true

-- ================================================================
-- Section: Log
-- ================================================================
s = m:section(NamedSection, "main", "frpc", translate("Log Settings"))

o = s:option(ListValue, "log_level", translate("Log Level"))
o:value("", translate("Default (info)"))
o:value("trace", "trace")
o:value("debug", "debug")
o:value("info", "info")
o:value("warn", "warn")
o:value("error", "error")
o.rmempty = true

o = s:option(Value, "log_max_days", translate("Log Retention (days)"),
	translate("Maximum number of days to keep log files"))
o.datatype = "uinteger"
o.placeholder = "3"
o.rmempty = true

-- ================================================================
-- Section: Advanced Client Settings
-- ================================================================
s = m:section(NamedSection, "main", "frpc", translate("Advanced"))

o = s:option(Flag, "login_fail_exit", translate("Exit on Login Failure"),
	translate("Exit frpc when login to server fails"))
o.default = "1"
o.rmempty = false

o = s:option(Value, "dns_server", translate("DNS Server"),
	translate("Custom DNS server address (e.g. 8.8.8.8)"))
o.rmempty = true

o = s:option(Value, "metadatas", translate("Metadatas"),
	translate("Client metadata separated by | (e.g. Key1:Value1|Key2:Value2)"))
o.rmempty = true
o.placeholder = "Key1:Value1|Key2:Value2"

-- ================================================================
-- Section: Proxy List (TypedSection)
-- ================================================================
s = m:section(TypedSection, "proxy", translate("Proxy List"),
	translate("Each proxy defines a tunnel through the frp server."))
s.template = "cbi/tblsection"
s.addremove = false
s.anonymous = true
s.extedit = luci.dispatcher.build_url("admin", "services", "frpc", "client", "proxy", "%s")

function s.create(self, section)
	local name = TypedSection.create(self, section)
	if name then
		luci.http.redirect(luci.dispatcher.build_url("admin", "services", "frpc", "client", "proxy", name))
	end
end

o = s:option(Flag, "enabled", translate("Enable"))
o.rmempty = false
o.default = "1"
o.width = "5%"

o = s:option(DummyValue, "name", translate("Proxy Name"))
o.width = "15%"

o = s:option(DummyValue, "type", translate("Type"))
o.width = "10%"

function o.cfgvalue(self, section)
	local v = Value.cfgvalue(self, section)
	if v then return string.upper(v) end
	return ""
end

o = s:option(DummyValue, "local_ip", translate("Local IP"))
o.width = "15%"

o = s:option(DummyValue, "local_port", translate("Local Port"))
o.width = "10%"

o = s:option(DummyValue, "_target", translate("Target"))
o.width = "20%"

function o.cfgvalue(self, section)
	local proxy_type = m:get(section, "type") or ""
	local remote_port = m:get(section, "remote_port") or ""
	local custom_domains = m:get(section, "custom_domains") or ""
	local subdomain = m:get(section, "subdomain") or ""

	if proxy_type == "tcp" or proxy_type == "udp" or proxy_type == "sudp" then
		if remote_port ~= "" then
			return ":" .. remote_port
		end
	elseif proxy_type == "http" or proxy_type == "https" or proxy_type == "tcpmux" then
		local parts = {}
		if subdomain ~= "" then
			table.insert(parts, subdomain .. ".*")
		end
		if custom_domains ~= "" then
			table.insert(parts, custom_domains)
		end
		if #parts > 0 then
			return table.concat(parts, ", ")
		end
	elseif proxy_type == "stcp" or proxy_type == "xtcp" then
		local role = m:get(section, "role") or ""
		local server_name = m:get(section, "server_name") or ""
		if role == "visitor" and server_name ~= "" then
			return "-> " .. server_name
		elseif role == "server" then
			return "(server)"
		end
	end
	return ""
end

-- "Add" button at the bottom of the proxy list
o = s:option(Button, "_add", translate("Add Proxy"))
o.inputstyle = "add"
o.write = function(self, section)
	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "frpc", "client", "proxy", "new"))
end

m.on_after_commit = function(self)
	luci.util.exec("/etc/init.d/frpc restart >/dev/null 2>&1 &")
end

return m
