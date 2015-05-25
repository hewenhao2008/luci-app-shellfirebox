--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

$Id$

]]--

local fs  = require "nixio.fs"
local sys = require "luci.sys"
local uci = require "luci.model.uci".cursor()
local shellfirebox = require "luci.shellfirebox"
local debugger = require "luci.debugger" 

local m = Map("shellfirebox", translate("Shellfire Box"))
m.pageaction = false

local general = m:section(TypedSection, "vpn")
general.template = "shellfirebox/main"

return m