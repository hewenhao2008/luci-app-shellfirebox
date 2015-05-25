	local shellfirebox = require "luci.shellfirebox"
	local debugger = require "luci.debugger"
	i18n = require "luci.i18n"
	
function getAjaxConnectionState()
local statecode = shellfirebox.getConnectionState()
    
    local result = {}
     
    
    
    if statecode == "processDisconnected"
    then
      result.state = "disconnected"
      result.stateText = i18n.translate("Disconnected")
      result.actionText = i18n.translate("Connect")
      
    elseif statecode == "processConnecting" or statecode == "processRestarting"
    then   
      result.state = "connecting"
      result.stateText = i18n.translate("Connecting...")
      result.actionText = i18n.translate("Abort")
    
    elseif statecode == "succesfulConnect"
    then   
      result.state = "connected"
      result.stateText = i18n.translate("Connected")
      result.actionText = i18n.translate("Disconnect")
    
    elseif statecode == "serverChange"
    then   
      result.state = "waiting"
      result.stateText = i18n.translate("Changing Server...")
    
    elseif     statecode == "failedPassPhrase"
        or statecode == "certificateInvalid"
        or statecode == "allTapInUse"
        or statecode == "notEnoughPrivileges"
        or statecode == "tapDriverTooOld"
        or statecode == "generalError"
        or statecode == "tapDriverNotFound"
        or statecode == "gatewayFailed"
    then
      result.state = "error"
      result.stateText = i18n.translate("Connection Failed")
      result.actionText = i18n.translate("Connect")
    
    else
      result.state = "unknown"
      result.stateText = i18n.translate("Status Unknown")
      result.actionText = i18n.translate("Connect")
    
    end   
    
    luci.http.prepare_content("application/json")
    luci.http.write_json(result)

    return
end
	
function getAjaxSelectedServer()
    local selectedserver = shellfirebox.getSelectedServerDetails()
    luci.http.prepare_content("application/json")
    luci.http.write_json(selectedserver)

    return

end

function getAjaxServerList()
    local serverlist = shellfirebox.getServerList()

    luci.http.prepare_content("application/json")
    luci.http.write_json(serverlist)

    return
end
	
function handleAjax()
	
	if luci.http.formvalue("selectedserver") == "1" then
		return getAjaxSelectedServer()
	end

	if luci.http.formvalue("connectionstate") == "1" then
		return getAjaxConnectionState()
	end

	if luci.http.formvalue("serverlist") == "1" then
	  return getAjaxServerList()
	end

	if luci.http.formvalue("serverlistrefresh") == "1" then
		shellfirebox.refreshServerList()

		return
	end

end

function getAjaxAdvancedModeText()
  if shellfirebox.isAdvancedMode() then
    return luci.i18n.translate("disable advanced mode")
  else
    return luci.i18n.translate("enable advanced mode")
  end
end

function getAjaxLanguageText()
  if shellfirebox.getLanguage() == "de" then
    return luci.i18n.translate("switch to English")
  else
    return luci.i18n.translate("switch to German")
  end
end