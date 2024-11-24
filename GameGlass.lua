-- GameGlass
--
-- @author  Grisu118 - VertexDezign.net
-- @history     v1.0.0.0 - 2024-11-18 - Initial implementation
-- @Descripion: Exports game state into an xml for gameglass
-- @web: https://grisu118.ch or https://vertexdezign.net
-- Copyright (C) Grisu118, All Rights Reserved.

local modDirectory = g_currentModDirectory
local modName = g_currentModName

source(Utils.getFilename("ValueMapper.lua", modDirectory))

---@class GameGlass
---@field debugger GrisuDebug
---@field exportEnabled boolean
---@field updateTimer number
---@field settingsXmlFile string
GameGlass = {}
GameGlass.STATE_FILE_NAME = "gameGlassInterface.xml"
GameGlass.XML_VERSION = 1
GameGlass.SETTINGS_XML = "gameGlassInterfaceSettings.xml"
GameGlass.SETTINGS_XML_VERSION = 1

local GameGlass_mt = Class(GameGlass)

---@return GameGlass
function GameGlass.init()
  ---@type GameGlass
  local self = {}

  setmetatable(self, GameGlass_mt)

  self.debugger = GrisuDebug:create("GameGlass")
  self.debugger:setLogLvl(GrisuDebug.TRACE)

  self.exportEnabled = false
  self.specLogLevel = GrisuDebug.INFO
  self.updateTimer = 0

  local modSettingsDir = getUserProfileAppPath() .. "modSettings/"
  self.settingsXmlFile = modSettingsDir .. GameGlass.SETTINGS_XML

  if not fileExists(self.settingsXmlFile) then
    self:writeDefaultSettings()
  end
  self:loadSettingsFromFile()

  self.debugger:info("GameGlass initialized")
  return self
end

function GameGlass:loadMap(filename)
  self.debugger:debug("GameGlass loading")

  if g_dedicatedServerInfo == nil then
    local appPath = getUserProfileAppPath()
    self.xmlFileLocation = appPath .. GameGlass.STATE_FILE_NAME
  end

  --self.debugger:tPrint("Vehicle",Vehicle)
  self.debugger:info("GameGlass loaded")
end

function GameGlass:writeDefaultSettings()
  self.debugger:trace("writeDefaultSettings")
  local xml = XMLFile.create("GGS", self.settingsXmlFile, "GGS")

  xml:setInt("GGS#version", 1)
  xml:setBool("GGS.exportEnabled", g_dedicatedServerInfo == nil)
  xml:setString("GGS.logging.level", "INFO")
  xml:setString("GGS.logging.specLevel", "INFO")

  xml:save()
  xml:delete()
end

function GameGlass:loadSettingsFromFile()
  self.debugger:trace("loadSettingsFromFile")
  local xml = XMLFile.load("GGS", self.settingsXmlFile)

  local version = xml:getInt("GGS#version", 0)
  if version ~= GameGlass.SETTINGS_XML_VERSION then
    --TODO proper handling?
    self.debugger:error("Unknown settings xml version, setting defaults values")
    self:writeDefaultSettings()
  end

  self.exportEnabled = xml:getBool("GGS.exportEnabled", true)
  local logLevel = xml:getString("GGS.logging.level", "INFO")
  local specLogLevel = xml:getString("GGS.logging.specLevel", "INFO")

  local parseLogLevel = GrisuDebug.parseLogLevel(logLevel)
  self.debugger:setLogLvl(parseLogLevel)
  self.specLogLevel = GrisuDebug.parseLogLevel(specLogLevel)

  xml:delete()
end

function GameGlass:update(dt)
  if self.exportEnabled == false then
    return
  end

  self.updateTimer = self.updateTimer + dt
  -- only update every 500ms
  if self.updateTimer < 500 then
    return
  end

  -- Execute the desired statement
  self:writeXMLFile()
  self.debugger:trace("Wrote xml file")

  -- Reset the timer after execution
  self.updateTimer = 0


end

function GameGlass:writeXMLFile()
  self.debugger:trace("Write xml file")

  local xml = XMLFile.create("GameGlass", self.xmlFileLocation, "GGI")
  xml:setInt("GGI#version", GameGlass.XML_VERSION)
  xml:setString("GGI#xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
  xml:setString("GGI#xsi:noNamespaceSchemaLocation", "https://raw.githubusercontent.com/VertexDezign/GameGlassInterface/refs/heads/main/gameGlassInterfaceSchema.xsd")
  self:populateXMLFromEnvironment(xml)
  self:populateXMLFromVehicle(xml)
  xml:save()
  xml:delete()
end

---@param XMLFile
function GameGlass:populateXMLFromEnvironment(xml)
  local environment = g_currentMission.environment

  -- export current hour (fixed 24h format)
  xml:setString("GGI.environment.time", string.format("%02d:%02d", g_currentMission.environment.currentHour, g_currentMission.environment.currentMinute))

  -- TODO add other stuff like day / wheater
end

---@param xml XMLFile
function GameGlass:populateXMLFromVehicle(xml)
  local vehicle = self.currentVehicle
  if vehicle == nil then
    -- no vehicle -> nothing to do
    return
  end

  xml:setInt("GGI.vehicle.speed", vehicle:getLastSpeed())
  xml:setString("GGI.vehicle.speed#unit", "km/h")
  xml:setString("GGI.vehicle.speed#direction", ValueMapper.mapDirection(vehicle:getDrivingDirection()))
  self:populateXMLFromMotorized(xml)
  self:populateXMLFromAttacherJoints(xml)
end

---@param xml XMLFile
function GameGlass:populateXMLFromMotorized(xml)
  local mSpec = self.currentVehicle.spec_motorized
  if mSpec == nil then
    return
  end
  -- ignition state
  xml:setString("GGI.vehicle.motor#state", ValueMapper.mapMotorState(mSpec:getMotorState()))

  -- motor temp
  xml:setInt("GGI.vehicle.motor.temperatur", mSpec.motorTemperature.value)
  xml:setInt("GGI.vehicle.motor.temperatur#min", mSpec.motorTemperature.valueMin)
  xml:setInt("GGI.vehicle.motor.temperatur#max", mSpec.motorTemperature.valueMax)
  xml:setString("GGI.vehicle.motor.temperatur#unit", "°C")

  -- rpm
  local motor = mSpec:getMotor()
  xml:setInt("GGI.vehicle.motor.rpm", motor:getLastMotorRpm())
  xml:setInt("GGI.vehicle.motor.rpm#min", 0)
  xml:setInt("GGI.vehicle.motor.rpm#max", motor:getMaxRpm())
  -- motor load
  xml:setString("GGI.vehicle.motor.load", ValueMapper.mapMotorLoad(motor:getSmoothLoadPercentage()))
  xml:setInt("GGI.vehicle.motor.load#min", 0)
  xml:setInt("GGI.vehicle.motor.load#max", 100)
  xml:setString("GGI.vehicle.motor.load#unit", "%")
  -- gear
  xml:setBool("GGI.vehicle.motor.gear#isNeutral", motor:getIsInNeutral())
  xml:setString("GGI.vehicle.motor.gear#group", motor:getGearGroupToDisplay())
  xml:setString("GGI.vehicle.motor.gear", motor:getGearToDisplay())

  for fillTypeIndex, v in pairs(mSpec.consumersByFillType) do
    self:writeFillUnitToXML(xml, "GGI.vehicle.motor.fillUnits", fillTypeIndex, v.fillUnitIndex)
  end
end

---@param xml XMLFile
---@param path string
---@param fillTypeIndex number The index of the fillType
---@param fillUnitIndex number The index of the fillUnit
function GameGlass:writeFillUnitToXML(xml, path, fillTypeIndex, fillUnitIndex)
  local capacity = self.currentVehicle:getFillUnitCapacity(fillUnitIndex)
  local fillLevel = self.currentVehicle:getFillUnitFillLevel(fillUnitIndex)
  local fillLevelPercentage = self.currentVehicle:getFillUnitFillLevelPercentage(fillUnitIndex)
  local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
  local unit = fillType.unitShort
  local name = fillType.name
  local title = fillType.title

  local pathType = string.lower(name)
  xml:setInt(string.format("%s.%s", path, pathType), fillLevel)
  xml:setString(string.format("%s.%s#title", path, pathType), title)
  xml:setString(string.format("%s.%s#unit", path, pathType), unit)
  xml:setInt(string.format("%s.%s#capacity", path, pathType), capacity)
  xml:setString(string.format("%s.%s#fillLevelPercentage", path, pathType), ValueMapper.mapPercentage(fillLevelPercentage, 0))
end

---@param xml XMLFile
function GameGlass:populateXMLFromAttacherJoints(xml)
  local ajSpec = self.currentVehicle.spec_attacherJoints

  -- check if the current vehicle has attacher joins
  if ajSpec == nil then
    return
  end

  for index, attachedImplement in pairs(ajSpec.attachedImplements) do
    local position = self.currentVehicle:ggiGetAttacherJointPosition(attachedImplement)

    -- lua table index starts with 1, but xml index must start with 0
    local xmlBasePath = string.format("GGI.vehicle.attacher(%d)", index - 1)
    xml:setString(string.format("%s#position", xmlBasePath), position)

    ---@type Vehicle
    local object = attachedImplement.object
    if object ~= nil then
      xml:setString(xmlBasePath, object:getName())
    end
  end
end

---@param vehicle GameGlassSpec
function GameGlass:setCurrentVehicle(vehicle)
  self.currentVehicle = vehicle
end

function GameGlass:clearCurrentVehicle()
  self.currentVehicle = nil
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