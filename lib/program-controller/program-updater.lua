local event = require("event")
local term = require("term")
local internet = require("internet")
local shell = require("shell")
local filesystem = require("filesystem")
local computer = require("computer")

local classBuilder = require("lib.class-builder.index")

---Compare two semver-style version strings (e.g. "1.2.10") component-wise.
---@param a string
---@param b string
---@return number # -1 if a < b, 1 if a > b, 0 if equal
local function compareVersions(a, b)
  local aIter = a:gmatch("%d+")
  local bIter = b:gmatch("%d+")
  while true do
    local aPart = aIter()
    local bPart = bIter()

    if aPart == nil and bPart == nil then
      return 0
    end

    local aNumber = tonumber(aPart) or 0
    local bNumber = tonumber(bPart) or 0

    if aNumber ~= bNumber then
      return aNumber < bNumber and -1 or 1
    end
  end
end

---@param timeout number
---@return string
local function readWithTimeout(timeout)
  local input = ""

  local startX, startY = term.getCursor()

  while true do
    local signal, _, char, code = event.pull(timeout, "key_down")

    if signal == nil then
      return ""
    elseif code == 28 then
      term.write("\n")
      return input
    elseif char and char >= 32 and char <= 126 then
      input = input .. string.char(char)
      term.write(string.char(char))
    elseif code == 14 and #input > 0 then
      input = string.sub(input, 1, #input - 1)

      local calculatedX = startX + #input

      term.setCursor(calculatedX, startY)
      term.write(" ")
      term.setCursor(calculatedX, startY)
    end
  end
end

---@class ProgramUpdater
---@field program Program
---@field interval number
local programUpdater = {}

---@return ProgramUpdater
function programUpdater:constructor(program)
  self.program = program
  self.interval = 3600

  return self
end

---Get timer for check autoupdate
---@return function callback
---@return number times
---@return number interval
function programUpdater:checkUpdateTimer()
  local isUpdateNeededNotified = false

  local callback = function ()
    if isUpdateNeededNotified == true then
      return
    end

    local isUpdateNeeded = self:isUpdateNeeded()

    if isUpdateNeededNotified == false and isUpdateNeeded == true then
      event.push("log_warning", "[Autoupdate] New version released, update available.");
      event.push("log_warning", "[Autoupdate] Reboot program to auto install it.");
      isUpdateNeededNotified = true
    end
  end

  return callback, math.huge, self.interval
end

---Try auto update program
function programUpdater:autoUpdate()
  local isUpdateNeeded, isConfigUpdateNeeded, isSetupUpdateNeeded, isGTNHUpdateNeeded, remoteVersion = self:isUpdateNeeded()
  local currentVersion = self.program.version ~= nil and self.program.version.programVersion or "nil"

  term.setCursor(1, 1)
  term.write("Current version: "..currentVersion.."\n")
  term.write("Check for new version...\n")

  if isUpdateNeeded == false or remoteVersion == nil then
    term.write("Current version is latest\n")
    os.sleep(3)
    term.clear()
    return
  end

  term.clear()
  term.write("Find new version: "..remoteVersion.programVersion.."\n\n")

  if isConfigUpdateNeeded then
    term.write("This update changes the format of the configuration file.\n")
    term.write("It will be necessary to manually overwrite the configuration file.\n\n")
  end

  if isSetupUpdateNeeded then
    term.write("This update requires changes in the multiblock setup, without which program may not work.\n\n")
  end

  if isGTNHUpdateNeeded then
    term.write("This update needed GTNH version: " .. remoteVersion.gtnhVersion .. " or higher.\n")
    term.write("If you're playing on an older version, the update might break the program.\n\n")
  end

  term.write("Do you want to update [y/n]?\n")
  term.write("==>")

  local userInput = readWithTimeout(60)

  if string.lower(userInput) ~= "y" then
    return
  end

  self:tryDownloadTarUtility()

  local url = "https://github.com/"..self.program.repository.."/releases/download/v"..remoteVersion.programVersion.."/"..self.program.archiveName..".tar"

  term.clear()
  term.write("Updating to version: "..remoteVersion.programVersion.."\n")

  self:downloadAndInstall(url)

  if isConfigUpdateNeeded then
    event.push("log_warning", "[Autoupdate] The format of the configs has been updated. It is necessary to manually rewrite the configuration file.");

    term.write("The format of the configs has been updated. It is necessary to manually rewrite the configuration file.\n")
    term.write("After rewriting the configuration file, do not forget to restart your computer.\n")
    term.write("Press [Enter] to confirm")

    term.read()
  else
    shell.execute("mv config.old.lua config.lua")
  end

  term.clear()
  term.write("Update completed\n")
  os.sleep(3)

  if isConfigUpdateNeeded == false then
    computer.shutdown(true)
    return
  end

  self.program:exit()
end

---Get latest version number
---@return ProgramVersion|nil
---@private
function programUpdater:getLatestVersionNumber()
  local versionFileUrl = "https://raw.githubusercontent.com/"..self.program.repository.."/refs/heads/"..self.program.version.branch.."/version.lua"

  local requestResult = internet.request(versionFileUrl)

  if not requestResult then
    return nil
  end

  local success, result = pcall(requestResult)

  if not success then
    return nil
  end

  for chunk in requestResult do
    result = result..chunk
  end

  return load(result)()
end

---Check if update is needed
---@return boolean # Need program update
---@return boolean # Need config update
---@return boolean # Need setup update
---@return boolean # Need gtnh update
---@return ProgramVersion|nil # Remote version
---@private
function programUpdater:isUpdateNeeded()
  if self.program.version == nil or internet == nil then
    return false, false, false, false, nil
  end

  local remoteVersion = self:getLatestVersionNumber()

  if remoteVersion == nil then
    return false, false, false, false, nil
  end

  local isUpdateNeeded = compareVersions(remoteVersion.programVersion, self.program.version.programVersion) > 0
  local isConfigUpdateNeeded = remoteVersion.configVersion > self.program.version.configVersion
  local isSetupUpdateNeeded = remoteVersion.setupVersion > self.program.version.setupVersion
  local isGTNHUpdateNeeded = compareVersions(remoteVersion.gtnhVersion, self.program.version.gtnhVersion) > 0

  return isUpdateNeeded, isConfigUpdateNeeded, isSetupUpdateNeeded, isGTNHUpdateNeeded, remoteVersion
end

---Download and install tar utility if not installed
---@private
function programUpdater:tryDownloadTarUtility()
  if filesystem.exists("/bin/tar.lua") then
    return
  end

  local tarManUrl = "https://raw.githubusercontent.com/mpmxyz/ocprograms/master/usr/man/tar.man"
  local tarBinUrl = "https://raw.githubusercontent.com/mpmxyz/ocprograms/master/home/bin/tar.lua"

  shell.setWorkingDirectory("/usr/man")
  shell.execute("wget -fq "..tarManUrl)
  shell.setWorkingDirectory("/bin")
  shell.execute("wget -fq "..tarBinUrl)
end

---Download and install latest version
---@param url string
---@private
function programUpdater:downloadAndInstall(url)
  shell.setWorkingDirectory("/home")
  shell.execute("mv config.lua config.old.lua")
  shell.execute("wget -fq "..url.." program.tar")
  shell.execute("tar -xf program.tar")
  shell.execute("rm program.tar")
end

return classBuilder.createClass(programUpdater, programUpdater.constructor, "ProgramUpdater")