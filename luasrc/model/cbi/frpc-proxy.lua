-- frpc-proxy.lua: Detail editing page for a single proxy entry
-- This model is loaded when the user clicks "edit" on a proxy row or creates a new proxy.
-- The section name is passed via the URL path (arg[1]).

local m, s, o
local section = arg[1]

-- If no section specified, redirect back to main page
if not section or section == "" then
	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "frpc", "client"))
	return
end

-- Handle "new" section: create a placeholder and redirect to its edit page
if section == "new" then
	local uci = require "luci.model.uci".cursor()
	local new_name = uci:section("frpc", "proxy", nil, {
		name = "",
		type = "tcp",
		local_ip = "127.0.0.1",
		local_port = "",
		remote_port = "",
		enabled = "1"
	})
	uci:save("frpc")
	uci:commit("frpc")
	if new_name then
		luci.http.redirect(luci.dispatcher.build_url("admin", "services", "frpc", "client", "proxy", new_name))
	else
		luci.http.redirect(luci.dispatcher.build_url("admin", "services", "frpc", "client"))
	end
	return
end

-- Try to determine if this is a named section (by name) or anonymous section (by hash)
local uci = require "luci.model.uci".cursor()
local real_section = section
local section_type = uci:get("frpc", section)

-- If not found by hash, try to find by name
if not section_type then
	uci:foreach("frpc", "proxy", function(s)
		if s.name == section then
			real_section = s[".name"]
			section_type = "proxy"
		end
	end)
end

-- If still not found, redirect back
if not section_type then
	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "frpc", "client"))
	return
end

-- Create the Map for the specific proxy section
m = Map("frpc", translate("Proxy Configuration"))

s = m:section(NamedSection, real_section, "proxy", translate("Proxy Settings"))
s.addremove = false
s.anonymous = true

-- Tabs
s:tab("basic", translate("Basic Settings"))
s:tab("advanced", translate("Advanced Settings"))

-- === Basic Settings Tab ===

o = s:taboption("basic", Flag, "enabled", translate("Enable"))
o.default = "1"
o.rmempty = false

o = s:taboption("basic", Value, "name", translate("Proxy Name"))
o.rmempty = false

o = s:taboption("basic", ListValue, "type", translate("Type"))
o:value("tcp", "TCP")
o:value("udp", "UDP")
o:value("http", "HTTP")
o:value("https", "HTTPS")
o:value("stcp", "STCP")
o:value("xtcp", "XTCP")
o:value("sudp", "SUDP")
o.default = "tcp"
o.rmempty = false

o = s:taboption("basic", Value, "local_ip", translate("Local IP"),
	translate("Local service IP address"))
o.datatype = "ipaddr"
o.placeholder = "127.0.0.1"
o.default = "127.0.0.1"

o = s:taboption("basic", Value, "local_port", translate("Local Port"),
	translate("Local service port"))
o.datatype = "port"
o.rmempty = false

o = s:taboption("basic", Value, "remote_port", translate("Remote Port"),
	translate("Port on the frps server to expose"))
o.datatype = "port"
o.rmempty = true
o:depends("type", "tcp")
o:depends("type", "udp")
o:depends("type", "sudp")

o = s:taboption("basic", Value, "custom_domains", translate("Custom Domains"),
	translate("Comma-separated list of custom domains"))
o.rmempty = true
o:depends("type", "http")
o:depends("type", "https")

o = s:taboption("basic", Value, "subdomain", translate("Subdomain"),
	translate("Subdomain for HTTP/HTTPS proxy"))
o.rmempty = true
o:depends("type", "http")
o:depends("type", "https")

o = s:taboption("basic", ListValue, "plugin_type", translate("Plugin"))
o:value("", translate("None"))
o:value("socks5", "socks5")
o:value("http_proxy", "http_proxy")
o:value("static_file", "static_file")
o:value("unix_domain_socket", "unix_domain_socket")
o:value("http2socks", "http2socks")
o:value("sni", "sni")
o.rmempty = true

o = s:taboption("basic", Value, "plugin_user", translate("Plugin User"))
o.rmempty = true
o:depends("plugin_type", "socks5")
o:depends("plugin_type", "http_proxy")

o = s:taboption("basic", Value, "plugin_pass", translate("Plugin Password"))
o.password = true
o.rmempty = true
o:depends("plugin_type", "socks5")
o:depends("plugin_type", "http_proxy")

-- === Advanced Settings Tab ===

o = s:taboption("advanced", ListValue, "use_encryption", translate("Encryption"),
	translate("Enable encryption for this proxy (true/false)"))
o:value("", translate("Default"))
o:value("true", translate("Yes"))
o:value("false", translate("No"))
o.rmempty = true

o = s:taboption("advanced", ListValue, "use_compression", translate("Compression"),
	translate("Enable compression for this proxy (true/false)"))
o:value("", translate("Default"))
o:value("true", translate("Yes"))
o:value("false", translate("No"))
o.rmempty = true

o = s:taboption("advanced", Value, "bandwidth_limit", translate("Bandwidth Limit"),
	translate("Bandwidth limit, e.g. 100KB or 1MB"))
o.rmempty = true

o = s:taboption("advanced", ListValue, "bandwidth_limit_mode", translate("Bandwidth Limit Mode"),
	translate("client or server"))
o:value("", translate("Default"))
o:value("client", "client")
o:value("server", "server")
o.rmempty = true

o = s:taboption("advanced", Value, "pool_count", translate("Connection Pool"),
	translate("Number of connections to keep in connection pool"))
o.datatype = "uinteger"
o.rmempty = true

o = s:taboption("advanced", ListValue, "health_check_type", translate("Health Check Type"),
	translate("Health check type: tcp or http"))
o:value("", translate("None"))
o:value("tcp", "TCP")
o:value("http", "HTTP")
o.rmempty = true

o = s:taboption("advanced", Value, "health_check_timeout_s", translate("Health Check Timeout (s)"))
o.datatype = "uinteger"
o.rmempty = true

o = s:taboption("advanced", Value, "health_check_max_failed", translate("Max Health Check Failures"))
o.datatype = "uinteger"
o.rmempty = true

o = s:taboption("advanced", Value, "health_check_interval_s", translate("Health Check Interval (s)"))
o.datatype = "uinteger"
o.rmempty = true

o = s:taboption("advanced", Value, "http_user", translate("HTTP Basic Auth User"),
	translate("Username for HTTP basic authentication"))
o.rmempty = true
o:depends("type", "http")
o:depends("type", "https")

o = s:taboption("advanced", Value, "http_pwd", translate("HTTP Basic Auth Password"),
	translate("Password for HTTP basic authentication"))
o.password = true
o.rmempty = true
o:depends("type", "http")
o:depends("type", "https")

o = s:taboption("advanced", TextValue, "locations", translate("Locations"),
	translate("URL routing paths, one per line"))
o.rmempty = true
o.rows = 3
o:depends("type", "http")

o = s:taboption("advanced", ListValue, "transport_type", translate("Transport Type"),
	translate("Transport type: tcp or websocket"))
o:value("", translate("Default"))
o:value("tcp", "TCP")
o:value("websocket", "WebSocket")
o.rmempty = true

o = s:taboption("advanced", ListValue, "proxy_protocol_version", translate("Proxy Protocol Version"),
	translate("Proxy protocol version: v1 or v2"))
o:value("", translate("Default"))
o:value("v1", "v1")
o:value("v2", "v2")
o.rmempty = true

-- STCP/XTCP options
o = s:taboption("advanced", Value, "secret_key", translate("Secret Key"),
	translate("Secret key for STCP/XTCP visitors"))
o.rmempty = true
o:depends("type", "stcp")
o:depends("type", "xtcp")

o = s:taboption("advanced", ListValue, "role", translate("Role"),
	translate("Role: server or visitor"))
o:value("", translate("Default"))
o:value("server", "server")
o:value("visitor", "visitor")
o.rmempty = true
o:depends("type", "stcp")
o:depends("type", "xtcp")

o = s:taboption("advanced", Value, "server_name", translate("Server Name"),
	translate("Server name for STCP/XTCP visitor to connect to"))
o.rmempty = true
o:depends("type", "stcp")
o:depends("type", "xtcp")

-- Static file plugin options
o = s:taboption("advanced", Value, "plugin_local_path", translate("Local Path"),
	translate("Local path for static_file plugin"))
o.rmempty = true
o:depends("plugin_type", "static_file")

o = s:taboption("advanced", Value, "plugin_strip_prefix", translate("Strip Prefix"),
	translate("Strip prefix for static_file plugin"))
o.rmempty = true
o:depends("plugin_type", "static_file")

o = s:taboption("advanced", Value, "plugin_http_user", translate("Plugin HTTP User"),
	translate("HTTP user for static_file plugin"))
o.rmempty = true
o:depends("plugin_type", "static_file")

o = s:taboption("advanced", Value, "plugin_http_passwd", translate("Plugin HTTP Password"),
	translate("HTTP password for static_file plugin"))
o.password = true
o.rmempty = true
o:depends("plugin_type", "static_file")

-- unix_domain_socket plugin
o = s:taboption("advanced", Value, "plugin_addr", translate("Plugin Address"),
	translate("Address for unix_domain_socket plugin"))
o.rmempty = true
o:depends("plugin_type", "unix_domain_socket")

-- sni plugin
o = s:taboption("advanced", Value, "sni_rewrite", translate("SNI Rewrite"),
	translate("SNI rewrite for sni proxy"))
o.rmempty = true
o:depends("plugin_type", "sni")

m.on_after_commit = function(self)
	luci.util.exec("/etc/init.d/frpc restart >/dev/null 2>&1 &")
end

return m
