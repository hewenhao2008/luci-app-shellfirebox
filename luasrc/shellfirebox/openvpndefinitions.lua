local debugger = require "luci.debugger"
local string = require "string"
local uci = require "luci.model.uci".cursor()
local shellfirebox = require "luci.shellfirebox"


function parseLine(openvpnoutput)
  debugger.log(openvpnoutput)
  for msgcode, stringtable in pairs(definitions) do

    for i, msgstring in ipairs(stringtable) do
      -- if openvpnoutput contains errrorstring write errorcode to uci
      if string.find(openvpnoutput, msgstring) then
        debugger.log("found match for " .. msgcode)
        shellfirebox.setConnectionState(msgcode)

      end
    end
  end
end

definitions = {
  succesfulConnect = {
    "Initialization Sequence Completed"
  },
  failedPassPhrase = {
    "TLS Error: Need PEM pass phrase for private key",
    "EVP_DecryptFinal:bad decrypt",
    "PKCS12_parse:mac verify failure",
    "Received AUTH_FAILED control message",
    "Auth username is empty"
  },
  certificateInvalid = {
    "error=certificate has expired",
    "error=certificate is not yet valid",
    "Cannot load certificate file"
  },
  processRestarting = {
    "process restarting",
    "Connection reset, restarting"
  },
  processDisconnected = {
    "process exiting"},
  allTapInUse = {
    "All TAP-Win32 adapters on this system are currently in use"
  },
  notEnoughPrivileges = {
    "route add command failed: returned error code 1",
    "FlushIpNetTable failed on interface"
  },
  tapDriverTooOld = {
    "This version of OpenVPN requires a TAP-Win32 driver that is at least version"
  },
  generalError = {
    "ERROR:", "due to fatal error"
  },
  tapDriverNotFound = {
    "There are no TAP-Win32 adapters on this system"
  },
  gatewayFailed = {
    "NOTE: unable to redirect default gateway"
  }

}
