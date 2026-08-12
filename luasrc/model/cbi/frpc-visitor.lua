-- frpc-visitor.lua: Visitor configuration page
-- This model defines the visitor-side configuration for STCP/XTCP/SUDP.
-- Visitors connect to a server-side proxy via P2P or relay.

local m, s, o

m = Map("frpc", translate("Visitor Settings"),
	translate("Configure a visitor to connect to a server-side STCP/XTCP/SUDP proxy."))

-- ================================================================
-- Tab 1: Basic Settings
-- ================================================================
s = m:section(NamedSection, arg[1], "visitor", translate("Basic Settings"))

o = s:option(ListValue, "type", translate("Type"))
o:value("stcp", "STCP")
o:value("xtcp", "XTCP")
o:value("sudp", "SUDP")
o.rmempty = false

o = s:option(Value, "server_user", translate("Server User"),
	translate("The user who started the server proxy (empty = same user)"))
o.rmempty = true

o = s:option(Value, "server_name", translate("Server Name"),
	translate("Name of the server-side proxy to connect to"))
o.rmempty = false

o = s:option(Value, "secret_key", translate("Secret Key"),
	translate("Must match the server proxy's secret key"))
o.rmempty = false

o = s:option(Value, "bind_addr", translate("Bind Address"),
	translate("Local address to bind (default: 127.0.0.1)"))
o.placeholder = "127.0.0.1"
o.rmempty = true

o = s:option(Value, "bind_port", translate("Bind Port"),
	translate("Local port to bind for incoming connections"))
o.datatype = "port"
o.rmempty = false

-- ================================================================
-- Tab 2: Transport
-- ================================================================
s = m:section(NamedSection, arg[1], "visitor", translate("Transport"))

o = s:option(Flag, "use_encryption", translate("Encryption"),
	translate("Enable encryption for this visitor connection"))
o.default = "0"
o.rmempty = false

o = s:option(Flag, "use_compression", translate("Compression"),
	translate("Enable compression for this visitor connection"))
o.default = "0"
o.rmempty = false

o = s:option(Value, "pool_count", translate("Connection Pool"),
	translate("Number of connections to pool"))
o.datatype = "uinteger"
o.placeholder = "1"
o.rmempty = true

o = s:option(ListValue, "transport_type", translate("Transport Type"),
	translate("Transport type for visitor connections"))
o:value("", translate("Default"))
o:value("tcp", "TCP")
o:value("kcp", "KCP")
o:value("quic", "QUIC")
o:value("wss", "WebSocket TLS")
o:value("wso", "WebSocket (wso)")
o.rmempty = true

o = s:option(Value, "bandwidth_limit", translate("Bandwidth Limit"),
	translate("Bandwidth limit (e.g. 10MB, 1MB)"))
o.rmempty = true

o = s:option(ListValue, "bandwidth_limit_mode", translate("Bandwidth Limit Mode"))
o:value("", translate("Default"))
o:value("client", "client")
o:value("server", "server")
o:value("visitor", "visitor")
o.rmempty = true

-- ================================================================
-- Tab 3: NAT Traversal (XTCP only)
-- ================================================================
s = m:section(NamedSection, arg[1], "visitor", translate("NAT Traversal"),
	translate("XTCP P2P NAT traversal settings"))

o = s:option(ListValue, "protocol", translate("Protocol"),
	translate("P2P protocol for XTCP"))
o:value("", translate("Default"))
o:value("quic", "QUIC")
o:value("kcp", "KCP")
o:value("tcp", "TCP")
o.rmempty = true
o:depends("type", "xtcp")

o = s:option(Flag, "keep_tunnel_open", translate("Keep Tunnel Open"),
	translate("Keep the tunnel open even when no visitors are connected"))
o.default = "0"
o.rmempty = false
o:depends("type", "xtcp")

o = s:option(Value, "max_retries", translate("Max Retries"),
	translate("Maximum number of retries for XTCP connection"))
o.datatype = "uinteger"
o.rmempty = true
o:depends("type", "xtcp")

o = s:option(ListValue, "fallback_to", translate("Fallback To"),
	translate("Fallback to another visitor type on failure"))
o:value("", translate("None"))
o:value("stcp", "STCP")
o.rmempty = true
o:depends("type", "xtcp")

o = s:option(Value, "fallback_timeout_ms", translate("Fallback Timeout (ms)"),
	translate("Timeout in milliseconds before fallback"))
o.datatype = "uinteger"
o.rmempty = true
o:depends("type", "xtcp")

m.on_after_commit = function(self)
	luci.util.exec("/etc/init.d/frpc restart >/dev/null 2>&1 &")
end

return m
