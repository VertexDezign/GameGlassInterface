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
---@return string The load in percent as float
function ValueMapper.mapMotorLoad(load)
  if load < 0 then
    return "0"
  else
    return ValueMapper.mapPercentage(load, 2)
  end
end

---@param value number 0..1
---@param decimals number How much decimals it should return, defaults to 2
---@return string The formated value as percentage
function ValueMapper.mapPercentage(value, decimals)
  if not decimals or decimals < 0 then
    decimals = 2
  end
  local percentage = value * 100
  return string.format("%." .. tostring(decimals) .. "f", percentage)
end