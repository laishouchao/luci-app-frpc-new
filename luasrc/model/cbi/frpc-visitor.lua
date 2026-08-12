-- frpc-visitor.lua: Detail editing page for a single visitor entry
-- This model is loaded when the user clicks "edit" on a visitor row or creates a new visitor.
-- The section name is passed via the URL path (arg[1]).

local m, s, o
local section = arg[1]

-- If no section specified, redirect back to visitors page
if not section or section == "" then
	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "frpc", "visitors"))
	return
end

-- Handle "new" section: create a placeholder and redirect to its edit page
if section == "new" then
	local uci = require "luci.model.uci".cursor()
	local new_name = uci:section("frpc", "visitor", nil, {
		name = "",
		type = "stcp",
		server_user = "",
		server_name = "",
		secret_key = "",
		bind_addr = "127.0.0.1",
		bind_port = "",
		enabled = "1"
	})
	uci:save("frpc")
	uci:commit("frpc")
	if new_name then
		luci.http.redirect(luci.dispatcher.build_url("admin", "services", "frpc", "visitors", "visitor", new_name))
	else
		luci.http.redirect(luci.dispatcher.build_url("admin", "services", "frpc", "visitors"))
	end
	return
end

-- Try to determine if this is a named section (by name) or anonymous section (by hash)
local uci = require "luci.model.uci".cursor()
local real_section = section
local section_type = uci:get("frpc", section)

-- If not found by hash, try to find by name
if not section_type then
	uci:foreach("frpc", "visitor", function(s)
		if s.name == section then
			real_section = s[".name"]
			section_type = "visitor"
		end
	end)
end

-- If still not found, redirect back
if not section_type then
	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "frpc", "visitors"))
	return
end

-- Create the Map for the specific visitor section
m = Map("frpc", translate("Visitor Configuration"))

s = m:section(NamedSection, real_section, "visitor", translate("Visitor Settings"))
s.addremove = false
s.anonymous = true

-- Tabs
s:tab("basic", translate("Basic Settings"))
s:tab("transport", translate("Transport"))
s:tab("nat", translate("NAT Traversal"))

-- === Basic Settings Tab ===

o = s:taboption("basic", Flag, "enabled", translate("Enable"))
o.default = "1"
o.rmempty = false

o = s:taboption("basic", Value, "name", translate("Visitor Name"))
o.rmempty = false

o = s:taboption("basic", ListValue, "type", translate("Type"))
o:value("stcp", "STCP")
o:value("xtcp", "XTCP")
o:value("sudp", "SUDP")
o.default = "stcp"
o.rmempty = false

o = s:taboption("basic", Value, "server_user", translate("Server User"),
	translate("Username of the server-side proxy owner (empty = same user)"))
o.rmempty = true
o.placeholder = ""

o = s:taboption("basic", Value, "server_name", translate("Server Name"),
	translate("Name of the server-side proxy to connect to"))
o.rmempty = false

o = s:taboption("basic", Value, "secret_key", translate("Secret Key"),
	translate("Secret key (must match the server-side proxy)"))
o.rmempty = true

o = s:taboption("basic", Value, "bind_addr", translate("Bind Address"),
	translate("Local address to listen on for incoming connections"))
o.datatype = "ipaddr"
o.placeholder = "127.0.0.1"
o.default = "127.0.0.1"

o = s:taboption("basic", Value, "bind_port", translate("Bind Port"),
	translate("Local port to listen on for incoming connections"))
o.datatype = "port"
o.rmempty = false

-- === Transport Tab ===

o = s:taboption("transport", ListValue, "use_encryption", translate("Encryption"),
	translate("Enable encryption for this visitor"))
o:value("", translate("Default"))
o:value("true", translate("Yes"))
o:value("false", translate("No"))
o.rmempty = true

o = s:taboption("transport", ListValue, "use_compression", translate("Compression"),
	translate("Enable compression for this visitor"))
o:value("", translate("Default"))
o:value("true", translate("Yes"))
o:value("false", translate("No"))
o.rmempty = true

o = s:taboption("transport", ListValue, "protocol", translate("Protocol"),
	translate("Transport protocol for P2P connection (XTCP only)"))
o:value("", translate("Default"))
o:value("quic", "QUIC")
o:value("kcp", "KCP")
o:value("tcp", "TCP")
o.rmempty = true
o:depends("type", "xtcp")

o = s:taboption("transport", Value, "pool_count", translate("Connection Pool"),
	translate("Number of connections to keep in connection pool"))
o.datatype = "uinteger"
o.rmempty = true

o = s:taboption("transport", Value, "bandwidth_limit", translate("Bandwidth Limit"),
	translate("Bandwidth limit, e.g. 100KB or 1MB"))
o.rmempty = true

o = s:taboption("transport", ListValue, "bandwidth_limit_mode", translate("Bandwidth Limit Mode"))
o:value("", translate("Default"))
o:value("client", "client")
o:value("server", "server")
o.rmempty = true

o = s:taboption("transport", ListValue, "transport_type", translate("Transport Type"),
	translate("Transport type: tcp or websocket"))
o:value("", translate("Default"))
o:value("tcp", "TCP")
o:value("websocket", "WebSocket")
o.rmempty = true

o = s:taboption("transport", Value, "metadatas", translate("Metadatas"),
	translate("Custom metadata separated by | (e.g. Key1:Value1|Key2:Value2)"))
o.rmempty = true
o.placeholder = "Key1:Value1|Key2:Value2"

-- === NAT Traversal Tab (XTCP only) ===

o = s:taboption("nat", Flag, "keep_tunnel_open", translate("Keep Tunnel Open"),
	translate("Keep the P2P tunnel open even when no traffic"))
o.default = "0"
o.rmempty = false
o:depends("type", "xtcp")

o = s:taboption("nat", Value, "max_retries", translate("Max Retries per Hour"),
	translate("Maximum number of connection retries per hour"))
o.datatype = "uinteger"
o.rmempty = true
o:depends("type", "xtcp")

o = s:taboption("nat", ListValue, "fallback_to", translate("Fallback To"),
	translate("Fallback to this proxy type when P2P fails"))
o:value("", translate("None"))
o:value("stcp", "STCP")
o:value("server", "server")
o.rmempty = true
o:depends("type", "xtcp")

o = s:taboption("nat", Value, "fallback_timeout_ms", translate("Fallback Timeout (ms)"),
	translate("Timeout in milliseconds before falling back"))
o.datatype = "uinteger"
o.placeholder = "1000"
o.rmempty = true
o:depends("fallback_to", "stcp")
o:depends("fallback_to", "server")

m.on_after_commit = function(self)
	luci.util.exec("/etc/init.d/frpc restart >/dev/null 2>&1 &")
end

return m
