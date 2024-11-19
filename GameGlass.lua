-- GameGlass
--
-- @author  Grisu118 - VertexDezign.net
-- @history     v1.0.0.0 - 2024-11-18 - Initial implementation
-- @Descripion: Exports game state into an xml for gameglass
-- @web: https://grisu118.ch or https://vertexdezign.net
-- Copyright (C) Grisu118, All Rights Reserved.

local modDirectory = g_currentModDirectory
local modName = g_currentModName

---@class GameGlass
---@field debugger GrisuDebug
---@field active boolean
GameGlass = {}
GameGlass.stateFileName = "gameglass.xml"

local GameGlass_mt = Class(GameGlass)

---@return GameGlass
function GameGlass.init()
  local self = {}

  setmetatable(self, GameGlass_mt)

  self.debugger = GrisuDebug:create("GameGlass")
  self.debugger:setLogLvl(GrisuDebug.TRACE)

  self.debugger:debug("GameGlass initialized")

  self.active = false

  return self
end

function GameGlass:loadMap(filename)
  self.debugger:info("GameGlass loading")

  self.active = false

  if g_dedicatedServerInfo == nil then
    self.active = true
    local appPath = getUserProfileAppPath()
    self.xmlFileLocation = appPath .. GameGlass.stateFileName
  end
end

function GameGlass:deleteMap()
end

function GameGlass:mouseEvent(posX, posY, isDown, isUp, button)
end

function GameGlass:keyEvent(unicode, sym, modifier, isDown)
end

function GameGlass:update(dt)
  if self.active == false then
    return
  end

end

function GameGlass:draw()
end

function GameGlass:writeXMLFile()
  self.debugger:trace("Write xml file")
end

function GameGlass:installSpec(typeManager)
  -- register spec
  g_specializationManager:addSpecialization("gameGlassSpec", "GameGlassSpec", Utils.getFilename("GameGlassSpec.lua", modDirectory), nil)

  -- add spec to vehicle types
  local totalCount = 0
  local modified = 0
  for typeName, typeEntry in pairs(typeManager:getTypes()) do
    totalCount = totalCount + 1
    if SpecializationUtil.hasSpecialization(Enterable, typeEntry.specializations) and
        not SpecializationUtil.hasSpecialization(Rideable, typeEntry.specializations) and
        not SpecializationUtil.hasSpecialization(ParkVehicle, typeEntry.specializations) then
      typeManager:addSpecialization(typeName, modName .. ".gameGlassSpec")
      modified = modified + 1
      self.debugger:trace("Adding GameGlass spec to " .. typeName)
    else
      self.debugger:trace("Not adding GameGlass spec to " .. typeName)
    end
  end

  self.debugger:info(string.format("Inserted GameGlass spec into %i of %i vehicle types", modified, totalCount))
end

local function installSpec(typeManager)
  if typeManager.typeName == "vehicle" then
    g_gameGlass:installSpec(typeManager)
  end
end

local function init()
  g_gameGlass = GameGlass.init()
  -- install spec
  TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, installSpec)

  -- add event listener
  addModEventListener(g_gameGlass)
end

init()