---@class ValueMapper
ValueMapper = {}

---@param direction number The direction
---@return string The enumified value
function ValueMapper.mapDirection(direction)
  if direction == 1 then
    return "FORWARD"
  elseif direction == -1 then
    return "BACKWARD"
  else
    return "STOPPED"
  end
end

---@param state number The ignition state
---@return string The enumified value
function ValueMapper.mapMotorState(state)
  if state == 1 then
    return "OFF"
  elseif state == 2 then
    return "STARTING"
  elseif state == 3 or state == 4 then
    return "ON"
  else
    return string.format("<unknown(%d))>", state)
  end
end

---@param load number 0..1
---@return number The load in percent as float
function ValueMapper.mapMotorLoad(load)
  if load < 0 then
    return 0
  else
    return load * 100
  end
end