local lsocket = require "lsocket"	-- https://github.com/cloudwu/lsocket
local hook = require "debughook"
local rdebug = require "remotedebug"
local aux = require "debugaux"

local so = assert(lsocket.connect("127.0.0.1", 8083))
assert(lsocket.select(nil, {so}, 1))	-- try to connect server for 1 sec

local function writestring(s)
	s = s .. "\r\n"
	local from = 1
	local len = #s
	while from <= len do
		local rd, wt = lsocket.select(nil, {so})
		from = from + assert(so:send(s:sub(from)))
	end
end

local filename = rdebug.getinfo(2).short_src
local handshake_url = '/session/' .. filename .. '?project=1234'
writestring(handshake_url)

local info = {}
local _print = print
local function print(...)
	rdebug.getinfo(1, info)
	local source = info.source
	local line = info.currentline
	writestring(table.concat({string.format("%s(%d):",source,line),...},"\t"))
end

hook.probe("@test2.lua",8, function()
	local f = aux.frame(1)
	print(f.a, f.b)
end)

hook.probe("@test2.lua",15, function()
	local f = aux.frame(1)
	print(f.s)
end)

rdebug.sethook(hook.hook)

