-- frpc-visitors.lua: Visitor list page
-- Shows all configured visitors (STCP/XTCP/SUDP) with edit/add/remove.

local m, s, o

m = Map("frpc", translate("Visitor List"),
	translate("Manage visitors that connect to server-side STCP/XTCP/SUDP proxies."))

s = m:section(TypedSection, "visitor", translate("Visitor List"))
s.template = "cbi/tblsection"
s.addremove = true
s.anonymous = true
s.extedit = luci.dispatcher.build_url("admin", "services", "frpc", "visitors", "visitor", "%s")

function s.create(self, section)
	local name = TypedSection.create(self, section)
	if name then
		luci.http.redirect(luci.dispatcher.build_url("admin", "services", "frpc", "visitors", "visitor", name))
	end
end

o = s:option(Flag, "enabled", translate("Enable"))
o.rmempty = false
o.default = "1"
o.width = "5%"

o = s:option(DummyValue, "name", translate("Visitor Name"))
o.width = "15%"

o = s:option(DummyValue, "type", translate("Type"))
o.width = "10%"
function o.cfgvalue(self, section)
	local v = Value.cfgvalue(self, section)
	if v then return string.upper(v) end
	return ""
end

o = s:option(DummyValue, "server_name", translate("Server Name"))
o.width = "15%"

o = s:option(DummyValue, "bind_addr", translate("Bind Address"))
o.width = "15%"
function o.cfgvalue(self, section)
	local addr = m:get(section, "bind_addr") or "127.0.0.1"
	local port = m:get(section, "bind_port") or ""
	if port ~= "" then
		return addr .. ":" .. port
	end
	return addr
end

o = s:option(DummyValue, "secret_key", translate("Secret Key"))
o.width = "15%"
function o.cfgvalue(self, section)
	local v = m:get(section, "secret_key") or ""
	if v ~= "" then
		return "****"
	end
	return ""
end

m.on_after_commit = function(self)
	luci.util.exec("/etc/init.d/frpc restart >/dev/null 2>&1 &")
end

return m
