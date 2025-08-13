setfenv(1, SpwMap)

Utils = {}

function Utils.log(msg)
  Utils.print(msg)
end

function Utils.print(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
  local f = DEFAULT_CHAT_FRAME
  f:AddMessage(
    "|cffccccffSpwMap: |cffffffff" ..
    (string.format(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10) or "nil"), 1,
    1, 1)
end

function Utils.mod(a, b)
  return a - (math.floor(a / b) * b)
end

function Utils.GetContinents()
  return { GetMapContinents() }
end

---Gets the world zone information
---@param continentIndex number
---@param zoneId number
---@return string name the zone name
---@return number xPos x position of the zone
---@return number yPos y position of the zone
---@return number width width of the zone
---@return number height height of the zone
---@return number zoneScale scale of the zone
function Utils.GetWorldZoneInfo(continentIndex, zoneId)
  local worldInfo = SpwMap.Map.MapInfo[continentIndex]
  if not worldInfo then
    return '?', 1, 0, 0, SPWMAP_DETAIL_FRAME_WIDTH, SPWMAP_DETAIL_FRAME_HEIGHT
  end

  local zoneInfo = SpwMap.Map.Area[zoneId]
  if not zoneInfo then
    return '?', 1, 0, 0, SPWMAP_DETAIL_FRAME_WIDTH, SPWMAP_DETAIL_FRAME_HEIGHT
  end

  local x = worldInfo.X + zoneInfo.x
  local y = worldInfo.Y + zoneInfo.y
  local scale = zoneInfo.scale * 100
  local width = scale * (zoneInfo.ScaleAdjX or 1)
  local height = scale / 1.5 * (zoneInfo.ScaleAdjY or 1)

  return zoneInfo.name, x, y, width, height, zoneInfo.scale
end
