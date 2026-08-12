module("luci.controller.frpc", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/frpc") then
		return
	end

	entry({"admin", "services", "frpc"}, alias("admin", "services", "frpc", "client"), _("frpc"), 60)
	entry({"admin", "services", "frpc", "client"}, cbi("frpc-client"), _("Settings"), 10)
	entry({"admin", "services", "frpc", "client", "proxy"}, cbi("frpc-proxy"), _("Proxy"), 20).leaf = true
	entry({"admin", "services", "frpc", "client", "status"}, call("action_status")).leaf = true
end

function action_status()
	local sys = require "luci.sys"
	local uci = require "luci.model.uci".cursor()
	local jsonc = require "luci.jsonc"

	local status = {
		running = false,
		pid = nil,
		uptime = nil,
		version = nil,
		config_generated = nil
	}

	-- Check if frpc is running
	local pid = nixio.fs.readfile("/var/run/frpc.pid")
	if pid and pid ~= "" then
		pid = pid:match("^%s*(.-)%s*$")
		if pid and pid:match("^%d+$") then
			local proc_exists = nixio.fs.access("/proc/" .. pid)
			if proc_exists then
				status.running = true
				status.pid = tonumber(pid)
			end
		end
	end

	-- Fallback: check via pidof
	if not status.running then
		local pidof_output = luci.util.exec("pidof frpc 2>/dev/null")
		if pidof_output and pidof_output:match("%d+") then
			status.running = true
			status.pid = tonumber(pidof_output:match("(%d+)"))
		end
	end

	-- Get frpc version
	local version_output = luci.util.exec("frpc --version 2>/dev/null")
	if version_output and version_output ~= "" then
		status.version = version_output:match("^%s*(.-)%s*$")
	end

	-- Check TOML config modification time
	if nixio.fs.access("/etc/frp/frpc.toml") then
		local stat = nixio.fs.stat("/etc/frp/frpc.toml")
		if stat and stat.mtime then
			status.config_generated = os.date("%Y-%m-%d %H:%M:%S", stat.mtime)
		end
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json(status)
end
