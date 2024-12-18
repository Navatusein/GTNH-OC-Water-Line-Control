-- Program Lib
-- Author: Navatusein
-- License: MIT
-- Version: 3.0

local event = require("event")
local thread = require("thread")
local component = require("component")
local keyboard = require("keyboard")
local term = require("term")
local internet = require("internet")
local shell = require("shell")
local filesystem = require("filesystem")
local computer = require("computer")

---@class ProgramVersion
---@field programVersion string
---@field configVersion number

---@class ProgramConfig
---@field logger Logger
---@field enableAutoUpdate boolean|nil
---@field version ProgramVersion|nil
---@field repository string|nil
---@field archiveName string|nil

---Try Catch
---@param callback function
---@return function
local function try(callback)
  return function(...)
    local result = table.pack(xpcall(callback, debug.traceback, ...))
    if not result[1] then
      event.push("exit", result[2])
    end
    return table.unpack(result, 2)
  end
end

---Download and install tar utility if not installed
local function tryDownloadTarUtility()
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

local program = {}

---Crate new List object from config
---@param config ProgramConfig
---@return Program
function program:newFormConfig(config)
  return self:new(config.logger, config.enableAutoUpdate, config.version, config.repository, config.archiveName)
end

---Crate new Program object
---@param logger Logger
---@param enableAutoUpdate? boolean
---@param version? ProgramVersion
---@param repository? string
---@param archiveName? string
---@return Program
function program:new(logger, enableAutoUpdate, version, repository, archiveName)

  ---@class Program
  local obj = {}

  obj.logger = logger
  obj.enableAutoUpdate = enableAutoUpdate
  obj.version = version
  obj.repository = repository
  obj.archiveName = archiveName

  obj.gpu = component.gpu

  obj.debug = false
  obj.coroutines = {}
  obj.keyHandlers = {}

  obj.defaultLoopInterval = 1/20
  obj.defaultWidth = 0
  obj.defaultHeight = 0
  obj.defaultForeground = 0
  obj.defaultBackground = 0

  obj.logo = nil
  obj.init = nil

  ---Register logo
  ---@param logo string[]
  function obj:registerLogo(logo)
    self.logo = logo
  end

  ---Register init function
  ---@param callback function
  function obj:registerInit(callback)
    self.init = callback
  end

  ---Register timer
  ---@param callback function
  ---@param times? number
  ---@param interval? number
  function obj:registerTimer(callback, times, interval)
    interval = interval or self.defaultLoopInterval

    local coroutineDescriptor = {
      type = "timer",
      interval = interval,
      callback = callback,
      times = times
    }

    table.insert(self.coroutines, coroutineDescriptor)
  end

  ---Register thread
  ---@param callback function
  function obj:registerThread(callback)
    local coroutineDescriptor = {
      type = "thread",
      callback = callback,
    }

    table.insert(self.coroutines, coroutineDescriptor)
  end

  ---Register button handler
  ---@param keyCode number
  ---@param callback function
  function obj:registerKeyHandler(keyCode, callback)
    if self.keyHandlers[keyCode] ~= nil then
      error("This Key Is Busy")
    end

    self.keyHandlers[keyCode] = try(callback)
  end

  ---Remove button handler
  ---@param keyCode number
  function obj:removeKeyHandler(keyCode)
    self.keyHandlers[keyCode] = nil
  end

  function obj:displayLogo()
    local width = #self.logo[1] + 2
    local height = #self.logo + 3

    self.gpu.setResolution(width, height)
    self.gpu.fill(1, 1, width, height, " ")

    term.setCursor(1, 2)

    for _, line in pairs(self.logo) do
      term.write(" "..line.."\n")
    end

    local currentVersion = self.version ~= nil and self.version.programVersion or "nil"

    term.write("\nversion: "..currentVersion.."\n")

    os.sleep(1)

    self.gpu.fill(1, 1, width, height, " ")
    self.gpu.setResolution(self.defaultWidth, self.defaultHeight)
  end

  ---Get latest version number
  ---@return ProgramVersion
  function obj:getLatestVersionNumber()
    local request = internet.request("https://raw.githubusercontent.com/"..self.repository.."/refs/heads/main/version.lua")
    local result = ""

    for chunk in request do
      result = result..chunk
    end

    return load(result)()
  end

  ---Check if update is needed
  ---@return boolean
  ---@return ProgramVersion|nil
  function obj:isUpdateNeeded()
    if self.version == nil then
      return false, nil
    end

    if internet == nil then
      return false, nil
    end

    local remoteVersion = obj:getLatestVersionNumber()

    local currentVersion = self.version.programVersion:gsub("[%D]", "")
    local latestVersion = remoteVersion.programVersion:gsub("[%D]", "")

    return latestVersion > currentVersion, remoteVersion
  end

  ---Download and install latest version
  ---@param url string
  function obj:downloadAndInstall(url)
    shell.setWorkingDirectory("/home")
    shell.execute("mv config.lua config.old.lua")
    shell.execute("wget -fq "..url.." program.tar")
    shell.execute("tar -xf program.tar")
    shell.execute("rm program.tar")
  end

  ---Update config file
  ---@param remoteVersion ProgramVersion
  ---@return boolean
  function obj:updateConfig(remoteVersion)
    local currentVersion = self.version.configVersion
    local latestVersion = remoteVersion.configVersion

    if currentVersion >= latestVersion then
      shell.execute("mv config.old.lua config.lua")
      return true
    end

    self.logger:warning("[Autoupdate] The format of the configs has been updated. It is necessary to manually rewrite the configuration file.")

    term.write("The format of the configs has been updated. It is necessary to manually rewrite the configuration file.\n")
    term.write("After rewriting the configuration file, do not forget to restart your computer.\n")
    term.write("Press [Enter] to confirm\n")

    term.read()

    return false
  end

  ---Try auto update program
  function obj:autoUpdate()
    local isUpdateNeeded, remoteVersion = self:isUpdateNeeded()
    term.setCursor(1, 1)
    term.write("Check for new version...\n")

    if isUpdateNeeded == false or remoteVersion == nil then
      term.write("Current version is latest\n")
      os.sleep(3)
      return
    end

    local url = "https://github.com/"..self.repository.."/releases/latest/download/"..self.archiveName..".tar"

    term.write("Updating to version "..remoteVersion.programVersion.."\n")

    self:downloadAndInstall(url)
    local allowRestart = self:updateConfig(remoteVersion)

    term.write("Update completed\n")
    os.sleep(3)

    if allowRestart then
      computer.shutdown(true)
      return
    end

    self:exit()
  end

  ---Program exit
  ---@param exception any
  function obj:exit(exception)
    for _, coroutine in pairs(self.coroutines) do
      if type(coroutine) == "table" and coroutine.kill then
        coroutine:kill()
      elseif type(coroutine) == "number" then
        event.cancel(coroutine)
      end
    end

    self.gpu.freeAllBuffers()

    self.gpu.setResolution(self.defaultWidth, self.defaultHeight)

    self.gpu.setForeground(self.defaultForeground)
    self.gpu.setBackground(self.defaultBackground)

    self.gpu.fill(1, 1, self.defaultWidth, self.defaultHeight, " ")

    term.setCursor(1, 1)

    if exception then
      io.stderr:write(exception)
      logger:error(exception)
      os.exit(1)
    else
      os.exit(0)
    end
  end

  ---Program start
  function obj:start()
    self.defaultWidth, self.defaultHeight = self.gpu.getResolution()

    self.defaultForeground = self.gpu.getForeground()
    self.defaultBackground = self.gpu.getBackground()

    if self.logo then
      self:displayLogo()
    end

    logger:init()

    if self.enableAutoUpdate then
      self:autoUpdate()
    end

    if self.init then
      try(self.init)()
    end

    for i = 1, #self.coroutines do
      local coroutine = self.coroutines[i]

      if coroutine.type == "timer" then
        self.coroutines[i] = event.timer(coroutine.interval, try(coroutine.callback), coroutine.times)
      elseif coroutine.type == "thread" then
        self.coroutines[i] = thread.create(try(coroutine.callback))
        self.coroutines[i]:detach()
      end
    end

    self:registerKeyHandler(keyboard.keys.q, function()
      event.push("exit")
    end)

    table.insert(self.coroutines, event.listen("key_up", try(function (_, address, char, keyCode)
      if self.debug == true then 
        logger:debug("Pressed ["..string.char(char).."]: "..keyCode.."\n")
      end

      if self.keyHandlers[keyCode] then

        if self.debug == true then 
          logger:debug("Action ["..string.char(char).."]: "..keyCode.."\n")
        end

        self.keyHandlers[keyCode]()
      end
    end)))

    local _, exception = event.pull("exit")
    self:exit(exception)
  end

  setmetatable(obj, self)
  self.__index = self
  return obj
end

return program