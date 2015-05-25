#!/usr/bin/lua
io = require("io")
string = require("string")

require "luci.shellfirebox.openvpndefinitions"


while true do
  local openvpnoutput = io.stdin:read()
  if openvpnoutput == nil then
    break
  else
    parseLine(openvpnoutput)
  end
end


