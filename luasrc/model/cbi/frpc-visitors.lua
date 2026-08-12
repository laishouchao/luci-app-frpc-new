-- frpc-visitors.lua: Visitor list page
-- Displays all visitors in a table with edit/delete/add capabilities.

local m, s, o

m = Map("frpc", translate("frpc Visitors"),
	translate("Manage STCP/XTCP/SUDP visitors to connect to remote server-side proxies."))

s = m:section(TypedSection, "visitor", translate("Visitor List"))
s.template = "cbi/tblsection"
s.addremove = false
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
o.width = "20%"

o = s:option(DummyValue, "_server_ref", translate("Server Reference"))
o.width = "20%"

function o.cfgvalue(self, section)
	local server_user = m:get(section, "server_user") or ""
	local server_name = m:get(section, "server_name") or ""
	if server_user ~= "" then
		return server_user .. "." .. server_name
	end
	return server_name
end

o = s:option(DummyValue, "bind_port", translate("Bind Port"))
o.width = "10%"

o = s:option(DummyValue, "_bind_addr", translate("Bind Address"))
o.width = "15%"

function o.cfgvalue(self, section)
	local bind_addr = m:get(section, "bind_addr") or "127.0.0.1"
	local bind_port = m:get(section, "bind_port") or ""
	if bind_port ~= "" then
		return bind_addr .. ":" .. bind_port
	end
	return bind_addr
end

-- "Add" button at the bottom of the visitor list
o = s:option(Button, "_add", translate("Add Visitor"))
o.inputstyle = "add"
o.write = function(self, section)
	luci.http.redirect(luci.dispatcher.build_url("admin", "services", "frpc", "visitors", "visitor", "new"))
end

m.on_after_commit = function(self)
	luci.util.exec("/etc/init.d/frpc restart >/dev/null 2>&1 &")
end

return m
