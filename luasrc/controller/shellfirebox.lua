-- Copyright 2008 Steven Barth <steven@midlink.org>
-- Copyright 2008 Jo-Philipp Wich <jow@openwrt.org>
-- Licensed to the public under the Apache License 2.0.

module("luci.controller.shellfirebox", package.seeall)
local shellfirebox = require "luci.shellfirebox"
require "luci.shellfirebox.ajax_handler"
local uci = require "luci.model.uci".cursor()
local debugger = require "luci.debugger"


function index()
  entry( {"admin", "services", "shellfirebox"}, template("shellfirebox/main"), _("Shellfire Box") )
  entry( {"admin", "services", "shellfirebox", "ajax_handler"}, call("handleAjax") )
  entry( {"admin", "services", "shellfirebox", "connect"}, call("connect") )
  entry( {"admin", "services", "shellfirebox", "disconnect"}, call("disconnect") )
  entry( {"admin", "services", "shellfirebox", "abort"}, call("abort"))
  entry( {"admin", "services", "shellfirebox", "setServerTo"}, call("setServerTo"))
  entry( {"admin", "services", "shellfirebox", "toggleAdvancedMode"}, call("toggleAdvancedMode"))
  entry( {"admin", "services", "shellfirebox", "toggleLanguage"}, call("toggleLanguage"))
  
  
end

function connect()
  shellfirebox.connect()
  luci.http.redirect(luci.dispatcher.build_url("admin", "services", "shellfirebox"))
end

function disconnect()
  shellfirebox.disconnect()
  luci.http.redirect(luci.dispatcher.build_url("admin", "services", "shellfirebox"))
end

function abort()
  shellfirebox.disconnect()
  luci.http.redirect(luci.dispatcher.build_url("admin", "services", "shellfirebox"))
end

function setServerTo()
  serverId = luci.http.formvalue("server")
  shellfirebox.setServerTo(serverId)
  luci.http.redirect(luci.dispatcher.build_url("admin", "services", "shellfirebox"))
end

function toggleAdvancedMode()
  shellfirebox.toggleAdvancedMode()
  
  luci.http.redirect(luci.dispatcher.build_url("admin", "services", "shellfirebox"))
end

function toggleLanguage()
  shellfirebox.toggleLanguage()
  
  luci.http.redirect(luci.dispatcher.build_url("admin", "services", "shellfirebox"))
end