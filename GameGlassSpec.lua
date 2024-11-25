---@class GameGlassSpecSpec
---@field debugger GrisuDebug
---@field actionEvents table

---@alias AttacherJointPosition "FRONT" | "BACK"


---@class GameGlassSpec : Vehicle
---@field spec_gameGlass GameGlassSpecSpec
GameGlassSpec = {}

function GameGlassSpec.prerequisitesPresent(specializations)
  return SpecializationUtil.hasSpecialization(Enterable, specializations)
end

function GameGlassSpec.registerEventListeners(vehicleType)
  SpecializationUtil.registerEventListener(vehicleType, "onLoad", GameGlassSpec)
  SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", GameGlassSpec)
  SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", GameGlassSpec)
  SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", GameGlassSpec)
end

function GameGlassSpec.registerFunctions(vehicleType)
  SpecializationUtil.registerFunction(vehicleType, "ggiGetCenterNode", GameGlassSpec.ggiGetCenterNode)
  SpecializationUtil.registerFunction(vehicleType, "ggiGetAttacherJointPosition", GameGlassSpec.ggiGetAttacherJointPosition)
  SpecializationUtil.registerFunction(vehicleType, "ggiActionEvent", GameGlassSpec.ggiActionEvent)
end

function GameGlassSpec:onLoad(savegame)
  self.spec_gameGlass = {
    debugger = GrisuDebug:create("GameGlassSpec"),
    actionEvents = {}
  }
  self.spec_gameGlass.debugger:setLogLvl(g_gameGlass.specLogLevel)
end

function GameGlassSpec:onEnterVehicle(isControlling)
  local spec = self.spec_gameGlass
  spec.debugger:trace(function()
    return "onEnterVehicle(" .. tostring(isControlling) .. ")"
  end)

  --spec.debugger:tPrint("vehicle.self.spec_motorized", self.spec_motorized)

  g_gameGlass:setCurrentVehicle(self)
end

function GameGlassSpec:onLeaveVehicle(wasEntered)
  local spec = self.spec_gameGlass
  spec.debugger:trace(function()
    return "onLeaveVehicle(" .. tostring(wasEntered) .. ")"
  end)

  g_gameGlass:clearCurrentVehicle()
end

function GameGlassSpec:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
  if self.isClient then
    local spec = self.spec_gameGlass
    self:clearActionEventsTable(spec.actionEvents)

    if not self:getIsActiveForInput(true) then
      return
    end

    local _, lowerFrontEventId = self:addActionEvent(spec.actionEvents, "GG_LOWER_FRONT", self, GameGlassSpec.actionEventLower, false, true, false, true, nil)
    g_inputBinding:setActionEventTextPriority(lowerFrontEventId, GS_PRIO_VERY_LOW)

    local _, lowerBackEventId = self:addActionEvent(spec.actionEvents, "GG_LOWER_BACK", self, GameGlassSpec.actionEventLower, false, true, false, true, nil)
    g_inputBinding:setActionEventTextPriority(lowerBackEventId, GS_PRIO_VERY_LOW)

    local _, foldFrontEventId = self:addActionEvent(spec.actionEvents, "GG_FOLD_FRONT", self, GameGlassSpec.actionEventFold, false, true, false, true, nil)
    g_inputBinding:setActionEventTextPriority(foldFrontEventId, GS_PRIO_VERY_LOW)

    local _, foldBackEventId = self:addActionEvent(spec.actionEvents, "GG_FOLD_BACK", self, GameGlassSpec.actionEventFold, false, true, false, true, nil)
    g_inputBinding:setActionEventTextPriority(foldBackEventId, GS_PRIO_VERY_LOW)

    local _, activateFrontEventId = self:addActionEvent(spec.actionEvents, "GG_ACTIVATE_FRONT", self, GameGlassSpec.actionEventActivate, false, true, false, true, nil)
    g_inputBinding:setActionEventTextPriority(activateFrontEventId, GS_PRIO_VERY_LOW)

    local _, activateBackEventId = self:addActionEvent(spec.actionEvents, "GG_ACTIVATE_BACK", self, GameGlassSpec.actionEventActivate, false, true, false, true, nil)
    g_inputBinding:setActionEventTextPriority(activateBackEventId, GS_PRIO_VERY_LOW)

  end

end

function GameGlassSpec:actionEventLower(actionName, inputValue, callbackState, isAnalog)
  self.spec_gameGlass.debugger:trace("actionEventLower called with actionName: %s, inputValue: %s, callbackState: %s, isAnalog: %s", actionName, inputValue, callbackState, isAnalog)
  local isPowered, powerWarning = self:getIsPowered()

  local debugger = self.spec_gameGlass.debugger
  self:ggiActionEvent(actionName, function(object, attachedImplement, forceState)
    local newState = forceState
    --getAllowsLowering is not to be implemented for pickup and foldable (this uses getIsFoldMiddleAllowed for lowering), but getIsLowered is
    local allowsLowering, warning = object:getAllowsLowering()

    --TODO improve this if
    if isPowered and (allowsLowering
        or object.spec_pickup ~= nil
        or (object.getIsFoldMiddleAllowed ~= nil
        and object:getIsFoldMiddleAllowed())) then
      if newState == nil then
        newState = not object:getIsLowered()
      end
      debugger:trace("Lowering is allowed, newState: %s", newState)
      object:setLoweredAll(newState, attachedImplement.jointDescIndex)
      return newState
    elseif warning ~= nil then
      g_currentMission:showBlinkingWarning(warning, 2000)
    elseif powerWarning ~= nil then
      g_currentMission:showBlinkingWarning(powerWarning, 2000)
    end
  end)
end

function GameGlassSpec:actionEventFold(actionName, inputValue, callbackState, isAnalog)
  self.spec_gameGlass.debugger:trace("actionEventFold called with actionName: %s, inputValue: %s, callbackState: %s, isAnalog: %s", actionName, inputValue, callbackState, isAnalog)
  local isPowered, powerWarning = self:getIsPowered()

  self:ggiActionEvent(actionName, function(object, attachedImplement, forceState)
    if object.spec_foldable == nil then
      return forceState
    end

    local fSpec = object.spec_foldable
    if #fSpec.foldingParts > 0 then
      local direction = object:getToggledFoldDirection()
      local allowed, warning = object:getIsFoldAllowed(direction, false)
      local requiresPower = fSpec.requiresPower
      local newState = forceState

      if allowed and (not requiresPower or isPowered) then
        if newState == nil then
          newState = direction == fSpec.turnOnFoldDirection
        end
        if newState then
          object:setFoldState(direction, true)
        else
          object:setFoldState(direction, false)

          if object:getIsFoldMiddleAllowed() and object.getAttacherVehicle ~= nil then
            local attacherVehicle = object:getAttacherVehicle()
            local attacherJointIndex = attacherVehicle:getAttacherJointIndexFromObject(object)

            if attacherJointIndex ~= nil then
              local moveDown = attacherVehicle:getJointMoveDown(attacherJointIndex)
              local targetMoveDown = direction == fSpec.turnOnFoldDirection

              if targetMoveDown ~= moveDown then
                attacherVehicle:setJointMoveDown(attacherJointIndex, targetMoveDown)
              end
            end
          end
        end
        return newState
      elseif warning ~= nil then
        g_currentMission:showBlinkingWarning(warning, 2000)
      elseif powerWarning ~= nil then
        g_currentMission:showBlinkingWarning(powerWarning, 2000)
      end
    end
  end)
end

function GameGlassSpec:actionEventActivate(actionName, inputValue, callbackState, isAnalog)
  self.spec_gameGlass.debugger:trace("actionEventActivate called with actionName: %s, inputValue: %s, callbackState: %s, isAnalog: %s", actionName, inputValue, callbackState, isAnalog)

  self:ggiActionEvent(actionName, function(object, attachedImplement, forceState)
    -- check if object has turned on thing
    local newState = forceState
    if object.getIsTurnedOn ~= nil and object:getCanToggleTurnedOn() and object:getCanBeTurnedOn() then
      if newState == nil then
        newState = not object:getIsTurnedOn()
      end
      object:setIsTurnedOn(newState)
      return newState
    end
  end)
end

---@param actionName string
---@param callback function
---@param forceState boolean
function GameGlassSpec:ggiActionEvent(actionName, callback, forceState)
  local ajSpec = self.spec_attacherJoints
  if ajSpec == nil then
    return
  end
  local targetPosition
  if string.endsWith(actionName, "FRONT") then
    targetPosition = "FRONT"
  else
    targetPosition = "BACK"
  end

  for index, attachedImplement in pairs(ajSpec.attachedImplements) do
    local position
    if forceState ~= nil then
      position = targetPosition
    else
      position = self:ggiGetAttacherJointPosition(attachedImplement)
    end
    local object = attachedImplement.object

    if position == targetPosition then
      local newState = callback(object, attachedImplement, forceState)
      if newState ~= nil then
        GameGlassSpec.ggiActionEvent(object, actionName, callback, newState)
      end
    end
  end
end

function GameGlassSpec:ggiGetCenterNode()
  if self.getAIRootNode ~= nil and type(self.getAIRootNode) == "function" then
    local node = self:getAIRootNode()
    if node ~= nil then
      return node
    end
  end
  if self.steeringAxleNode ~= nil and self.steeringAxleNode ~= 0 then
    return self.steeringAxleNode
  end
  return self.components[1].node
end

---@return AttacherJointPosition
function GameGlassSpec:ggiGetAttacherJointPosition(attachedImplement)
  local ajSpec = self.spec_attacherJoints
  --try to estimate if implement is in the front or back
  local jointDesc = ajSpec.attacherJoints[attachedImplement.jointDescIndex]

  local wx, wy, wz = getWorldTranslation(jointDesc.jointTransform)
  local _, _, lz = worldToLocal(self:ggiGetCenterNode(), wx, wy, wz)

  local position
  if lz > 0 then
    position = "FRONT"
  else
    position = "BACK"
  end
  return position
end