local luci  = {}

local io = require("io")
local https = require "ssl.https"  
                                 
local ltn12 = require("ltn12")
local debugger = require "luci.debugger" 
local sys = require "luci.sys"


luci.sys    = require "luci.sys"
local testfullps = luci.sys.exec("ps --help 2>&1 | grep BusyBox") --check which ps do we have
local psstring = (string.len(testfullps)>0) and  "ps w" or  "ps axfw" --set command we use to get pid

local shellfireboxTheme = "/luci-static/shellfirebox"
local bootstrapTheme = "/luci-static/bootstrap"


luci.util   =  require "luci.util"
local uci = require "luci.model.uci".cursor()
local json = require "luci.json"
local fs = require "luci.fs"
local string = require "string"

local configname = "shellfirebox"
local countrytable = require "luci.shellfirebox.countrytable"

-- local host = string.format("http://%s:%d", config.host, config.port or 80)
local host = "http://dev.shellfire.local.de"

local tonumber, ipairs, pairs, pcall, type, next, setmetatable, require, select, tostring =
  tonumber, ipairs, pairs, pcall, type, next, setmetatable, require, select, tostring

--- Shellfire Box library.
module "luci.shellfirebox"

--- Shellfire Box system utilities / process related functions.



function getServerList()
  local serverlist = {}
  uci:foreach(configname, "server", 
    function(section)
          serverlist[section.vpnServerId] = section
    end
  )

  if serverlist == nil then
    refreshServerList()
    serverlist = uci:get_all(configname, "server")
  end

  return serverlist
end

-- refresh the openvpn params for this box (changes with the selected server and protocol)
-- @return true if the refresh was succesful, false otherwise
function refreshOpenVpnParams()

  local newvpnparams, message = api.call("getOpenVpnParams")

  if newvpnparams ~= false then
    -- delete all servers from uci config file
    uci:delete_all(configname, "openvpnparams")
  
    uci:save(configname)
    uci:commit(configname)

    localparams = {}
    for k, v in pairs(newvpnparams) do
      cleankey = string.gsub(k, "-", "_")
      localparams[cleankey] = v
    end
      
    uci:section(configname, "openvpnparams", nil, localparams)
      
    uci:save(configname)
    uci:commit(configname)
    return true
  else
    return false, message
  end
end

-- selects a server on the backend - needs a refreshVpn afterwards
-- @return true if the refresh was succesful, false otherwise
function setServerTo(section)
  currentConnectionState = getConnectionState()

  local reconnect = false
  if currentConnectionState == "succesfulConnect" or currentConnectionState == "processConnecting" 
  then
    reconnect = true
    disconnect()
    luci.sys.exec("sleep 1")
  end  

  setConnectionState("serverChange")
  
  local serverid
  if type(section) == "table" then
    serverid = uci:get(configname, section, "vpnServerId")
  else
    serverid = section
  end
  
  local success, message = api.call("setServerTo", {vpnServerId = serverid})
  refreshOpenVpnParams()
  refreshVpn()
  refreshServerList()
  
  setConnectionState("processDisconnected")
  
  if reconnect then
    connect()
  end
  
  return success, message
  
end


-- refresh the shellfire vpn product details for this box
-- @return true if the refresh was succesful, false otherwise
function refreshVpn()
  
  local newvpndetails, message = api.call("getVpn")

  if newvpndetails ~= false then
    -- delete all servers from uci config file
    uci:delete_all(configname, "vpn")
    uci:save(configname)
    uci:commit(configname)

    uci:section(configname, "vpn", nil, newvpndetails)
      
    uci:save(configname)
    uci:commit(configname)
    return true
  else
    return false, message
  end
end

function getVpn()
  local name = uci:get_first(configname, "vpn")
  if name == nil then
    refreshVpn()
    name = uci:get_first(configname, "vpn")
  end

  return uci:get_all(configname, name)
end


-- refresh the certificates for this box from the server. should only be required for the initial setup or in case of reset.
-- @return true if the refresh was succesful, false otherwise
function refreshCertificates()
  
  local certs, message = api.call("getCertificates")

  if certs ~= false then
  
    local keydir = "/etc/keys/"
    
    if fs.isdirectory("/etc/keys/") == false then
      fs.mkdir(keydir)
    end

    for filename, filecontent in pairs(certs) do
      fs.writefile(keydir .. filename, filecontent)
    end
    -- TODO maybe evaluate proper content before writing, e.g. by content length 
    return true
  else
    return false, message
  end
end



-- generates this device's uid from its mac address
function generateUidFromMac() 
  local uid = "sfb" .. luci.util.trim(luci.sys.exec("echo -n \"ShellfireVpn\"`cat /sys/class/net/eth0/address` | md5sum | cut -f1 -d' '" ))
  
  return uid
end

function getUid() 
  local uid = uci:get_first(configname, "general", "uid")
  
  if (uid == nil) then
    uid = generateUidFromMac()
    
    local name = uci:get_first(configname, "general")
    if name ~= true then
      uci:section(configname, "general")
      name = uci:get_first(configname, "general")
    end
    
    uci:set(configname, name, "uid", uid)
    
    uci:save(configname)
    uci:commit(configname)    
  end

  return uid
end




api = {}
-- Call the Shellfire Json API and return parsed object
function api.call(action, params)

  local uid = getUid()
  
  local url = "https://www.shellfire.de/webservice/json.php?action=" .. action

  local requestbody = json.encode(params)

  local headers = {
      ["Content-Type"]            = "application/json";
      ["X-Authorization-Token"]   = uid;
      ["Content-Length"] = tostring(#requestbody)
    } 
  
  local responsebody = {}
   a,b,c=https.request{
    url = url,
    method = "POST",
    headers = headers,
    source = ltn12.source.string(requestbody),
    sink = ltn12.sink.table(responsebody)                                           
  }
  
  local result = ""
  if b == 200 then
    
    for i, k in pairs(responsebody) do
       result = result .. k
    end
    -- debugger.log(result)
    
    jsonresult = json.decode(result)
    -- debugger.log(jsonresult)
    
    if jsonresult.status == "success" then
      return jsonresult.data or true
    else
      return false, jsonresult.message
    end

  else
    debugger.log(a)
    debugger.log(b)
    debugger.log(c)
    
    return false
  end

  
end

function getPid()
  local pid = sys.exec("%s | grep openvpn | grep -v grep | grep -v openvpnparser | awk '{print $1}'" % { psstring } )
  return pid
end


function disconnect()
    local pid = getPid()
    if pid and #pid > 0 
    then
        sys.process.signal(pid,15)
    end
end

-- connects to the vpn / starts openvpn
function connect()
  setConnectionState("processConnecting")
  
  serverList = getServerList()
  if serverList == nil or #serverList == 0 then
    refreshServerList()
  end
  
  -- assemble start params
  local name = uci:get_first(configname, "openvpnparams")

  local allparams = ""

  uci:foreach(configname, "openvpnparams", 
    function(s)
    
      for k, v in pairs(s) do
        if string.sub(k,1,1) ~= "." and string.sub(k, 1,8) ~= "service" then  -- ignore the meta stuff
          local cleank = string.gsub(k, "_", "-")
        
          if v == "is-flag" then
            allparams = allparams .. "--" .. cleank .. " "
          else
            allparams = allparams .. "--" .. cleank .. " " .. tostring(v) .. " "
          end
        end
      end
    end  
  )

  local openvpnstart = "/usr/sbin/openvpn " .. allparams .. " | /usr/lib/lua/luci/shellfirebox/openvpnparser.lua &"

  debugger.log("start the openvpn bitch")
  debugger.log(openvpnstart)
  luci.sys.call(openvpnstart)
end


function getServerById(serverId)

  local result
  uci:foreach(configname, "server", 
    function(server)
      if server.vpnServerId == serverId then
        result = server
      end
    end
  )
  
  return result  

end

function getSelectedServerDetails()
  local vpn = getVpn()
  local selectedServerId = vpn.iServerId 
  
  local server = getServerById(selectedServerId)
  
  return server      
end

function getConnectionState()
  local state = uci:get_first("shellfirebox", "general", "openvpnstate")

  return state
end

function setConnectionState(state)
  local name = uci:get_first("shellfirebox", "general")
  uci:set("shellfirebox", name, "openvpnstate", state)
  
  uci:save("shellfirebox")
  uci:commit("shellfirebox")

end

--- Retrieve information about the list of Shellfire VPN Servers
-- @return true if the refresh was succesful, false otherwise
function refreshServerList()
  
  newserverlist, message = api.call("getServerlist")

  if newserverlist ~= false then
    -- delete all servers from uci config file
    uci:delete_all(configname, "server")
  
    uci:save(configname)
    uci:commit(configname)
      
    -- for every server
    for i, server in pairs(newserverlist) do
      server.iso = countrytable.getIsoCodeByCountry(server.country)

      uci:section(configname, "server", nil, server)
    end   
      
    uci:save(configname)
    uci:commit(configname)
  
    return true
  else
    return false, message
  end

end

function isAdvancedMode()
    local currentTheme = uci:get_first("luci", "core", "mediaurlbase")

    return currentTheme == bootstrapTheme
end

function setTheme(theme)
    uci:set("luci", "main", "mediaurlbase", theme)
    uci:save("luci")
    uci:commit("luci")
end

function toggleAdvancedMode()
  if isAdvancedMode() then
  debugger.log("isAdvancedMode")
    setTheme(shellfireboxTheme)
  else
  debugger.log("is regular mode")
    setTheme(bootstrapTheme)
  end
end

function getLanguage()
  return uci:get_first("luci", "core", "lang")
end

function setLanguage(lang)
    uci:set("luci", "main", "lang", lang)
    uci:save("luci")
    uci:commit("luci")
end

function toggleLanguage()
  local lang = getLanguage()
  
  if lang == "de" then 
    lang = "en"
  else
    lang = "de" 
  end
  
  setLanguage(lang)
  
end