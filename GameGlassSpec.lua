---@class GameGlassSpecSpec
---@field debugger GrisuDebug


---@class GameGlassSpec
---@field spec_gameGlass GameGlassSpecSpec
GameGlassSpec = {}

function GameGlassSpec.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Enterable, specializations)
end

function GameGlassSpec.registerEventListeners(vehicleType)
  SpecializationUtil.registerEventListener(vehicleType, "onLoad", GameGlassSpec)
  SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", GameGlassSpec)
  SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", GameGlassSpec)
end

function GameGlassSpec:onLoad(savegame)
  self.spec_gameGlass = {
    debugger = GrisuDebug:create("GameGlassSpec")
  }
  self.spec_gameGlass.debugger:setLogLvl(GrisuDebug.TRACE)
end

function GameGlassSpec:onEnterVehicle(isControlling)
  local spec = self.spec_gameGlass
  spec.debugger:trace("onEnterVehicle")
  -- currently nothing to do
end

function GameGlassSpec:onLeaveVehicle(wasEntered)
  local spec = self.spec_gameGlass
  spec.debugger:trace("onLeaveVehicle")
  -- currently nothing to do
end