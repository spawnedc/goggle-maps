setfenv(1, GoggleMaps)

local UNIT_FACTION_TO_FACTION_ID = {
  Horde = 4,
  Alliance = 2,
}

Utils = {}

function Utils.log(msg)
  Utils.print(msg)
end

function Utils.print(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
  local title = GetAddOnMetadata(GoggleMaps.name, "Title")
  local formattedMessage = (string.format(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10) or "nil")
  DEFAULT_CHAT_FRAME:AddMessage(title .. ": |r" .. formattedMessage)
end

function Utils.debug(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
  if GoggleMaps.DEBUG_MODE then
    local title = GetAddOnMetadata(GoggleMaps.name, "Title")
    local formattedMessage = (string.format(msg, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10) or "nil")
    DEFAULT_CHAT_FRAME:AddMessage(title .. " [D]: |r" .. formattedMessage)
  end
end

function Utils.mod(a, b)
  return a - (math.floor(a / b) * b)
end

--- Splits the given string by the given separator
---@param input string
---@param separator string
function Utils.splitString(input, separator)
  local t = {}
  -- gfind does not add a nil value if the string starts with the separator.
  if string.sub(input, 1, string.len(separator)) == separator then
    table.insert(t, nil)
  end
  for part in string.gfind(input, "([^" .. separator .. "]+)") do
    table.insert(t, part)
  end
  return unpack(t)
end

function Utils.numberFormat(num, precision)
  return string.format("%." .. precision .. "f", num)
end

function Utils.numberFormatter(precision)
  return function(value)
    return Utils.numberFormat(value, precision)
  end
end

function Utils.positionFormatter(value)
  if not value or value.x == nil or value.y == nil then
    return 'nil, nil'
  end
  return string.format("%.2f, %.2f", value.x, value.y)
end

function Utils.sizeFormatter(value)
  if not value or value.width == nil or value.height == nil then
    return 'nil, nil'
  end
  return string.format("%.2f, %.2f", value.width, value.height)
end

function Utils.GetContinents()
  return { GetMapContinents() }
end

---Constructs the zone name to mapId table
---@return table<number> zoneNameToMapId
---@return table<table<number>> continentZoneToMapId
function Utils.GetZoneNameToMapId()
  local continents = Utils.GetContinents()
  local zoneNameToMapId = {}
  local continentZoneToMapId = {}

  for continentIndex, continentName in ipairs(continents) do
    local mapNames = { GetMapZones(continentIndex) }
    continentZoneToMapId[continentIndex] = {}

    for n = 1, 99 do
      local mapId = continentIndex * 1000 + n
      local zoneInfo = GoggleMaps.Map.Area[mapId]
      if zoneInfo then
        for i, mapName in ipairs(mapNames) do
          if mapName == zoneInfo.name then
            zoneNameToMapId[mapName] = mapId
            zoneInfo.Zone = i
            continentZoneToMapId[continentIndex][i] = mapId
            break
          end
        end
      end
    end
  end

  return zoneNameToMapId, continentZoneToMapId
end

---Returns the continent id for a zoneId
---@param zoneId number
---@return integer
function Utils.getContinentId(zoneId)
  return math.floor(zoneId / 1000)
end

---Gets the world zone information
---@param mapId number
---@return string name the zone name
---@return number xPos x position of the zone
---@return number yPos y position of the zone
---@return number width width of the zone
---@return number height height of the zone
---@return number zoneScale scale of the zone
function Utils.GetWorldZoneInfo(mapId)
  local continentIndex = Utils.getContinentId(mapId)
  local worldInfo = GoggleMaps.Map.MapInfo[continentIndex]
  if not worldInfo then
    return '?', 1, 0, 0, 1024, 768
  end

  local zoneInfo = GoggleMaps.Map.Area[mapId]
  if not zoneInfo then
    return '?', 1, 0, 0, 1024, 768
  end

  local x = worldInfo.X + zoneInfo.x
  local y = worldInfo.Y + zoneInfo.y
  local scale = zoneInfo.scale * 100
  local width = scale
  local height = scale / 1.5

  return zoneInfo.name, x, y, width, height, zoneInfo.scale
end

function Utils.GetWorldContinentInfo(continentIndex)
  local info = GoggleMaps.Map.MapInfo[continentIndex]
  if not info then
    return
  end

  return info.Name, info.X, info.Y
end

---Gets the world position of the given coordinates of the mapId
---@param mapId number
---@param mapX number
---@param mapY number
---@return number
---@return number
function Utils.GetWorldPos(mapId, mapX, mapY)
  if not mapId then
    Utils.debug("No map id provided")
    return 0, 0
  end
  local continentIndex = Utils.getContinentId(mapId)
  local worldInfo = GoggleMaps.Map.MapInfo[continentIndex]
  if not worldInfo then
    Utils.debug("worldInfo not found for" .. mapId)
    return 0, 0
  end

  local zoneInfo = GoggleMaps.Map.Area[mapId]
  if not zoneInfo then
    Utils.debug("zoneInfo not found for" .. mapId)
    return 0, 0
  end

  local x = worldInfo.X + zoneInfo.x + mapX * zoneInfo.scale
  local y = worldInfo.Y + zoneInfo.y + mapY * zoneInfo.scale / 1.5

  return x, y
end

---Gets the zone position of the given world coordinates
---@param mapId number
---@param worldX number
---@param worldY number
---@return number
---@return number
function Utils.GetZonePosFromWorldPos(mapId, worldX, worldY)
  local continentIndex = Utils.getContinentId(mapId)
  local worldInfo = GoggleMaps.Map.MapInfo[continentIndex]
  if not worldInfo then
    Utils.debug("worldInfo not found for" .. mapId)
    return 0, 0
  end

  local zoneInfo = GoggleMaps.Map.Area[mapId]
  if not zoneInfo then
    Utils.debug("zoneInfo not found for" .. mapId)
    return 0, 0
  end

  local scale = zoneInfo.scale
  local zoneX = zoneInfo.x
  local zoneY = zoneInfo.y

  local x = (worldX - worldInfo.X - zoneX) / scale
  local y = (worldY - worldInfo.Y - zoneY) / scale * 1.5

  return x, y
end

---Gets the clipped size
---@param x number
---@param y number
---@param baseWidth number
---@param baseHeight number
---@param clipW number
---@param clipH number
---@return number frameWidth the clipped width
---@return number frameHeight the clipped height
function Utils.GetClippedSize(x, y, baseWidth, baseHeight, clipW, clipH)
  local vx1 = x
  local vx2 = x + baseWidth

  if vx1 < 0 then vx1 = 0 end
  if vx2 > clipW then vx2 = clipW end

  local vy1 = y
  local vy2 = y + baseHeight

  if vy1 < 0 then vy1 = 0 end
  if vy2 > clipH then vy2 = clipH end

  local frameWidth = vx2 - vx1
  local frameHeight = vy2 - vy1

  return frameWidth, frameHeight
end

---Clips a frame, also shows or hides and sets the size
---@param frame Frame
---@param x number
---@param y number
---@param baseWidth number
---@param baseHeight number
---@param clipW number
---@param clipH number
---@return boolean isShown
function Utils.ClipFrame(frame, x, y, baseWidth, baseHeight, clipW, clipH)
  local clippedW, clippedH = Utils.GetClippedSize(x, y, baseWidth, baseHeight, clipW, clipH)

  if clippedW < .3 or clippedH < .3 then
    -- Utils.print("Hiding %s", frame:GetName())
    frame:Hide()
    return false
  end

  frame:SetPoint("TopLeft", x, -y)
  frame:SetWidth(baseWidth)
  frame:SetHeight(baseHeight)

  frame:Show()

  return true
end

---Sets the current map to the given mapId
---@param mapId number
---@param reason string|nil
function Utils.setCurrentMap(mapId, reason)
  if mapId then
    local continent = Utils.getContinentId(mapId)
    local zone = GoggleMaps.Map.Area[mapId].Zone
    local newZone = Utils.GetWorldZoneInfo(continent, mapId)
    if reason then
      Utils.log(string.format("Map change reason: %s", reason))
    end
    SetMapZoom(continent, zone)
  end
end

function Utils.UnpackLocationRect(location)
  local x, y, w, h, name = Utils.splitString(location, "%^")
  return tonumber(x), tonumber(y), tonumber(w), tonumber(h), name
end

---Check if mouse is over a frame
---Returns XY offsets from bottom left corner or nil if not over
---@param frame Frame
---@return number|nil
---@return number|nil
function Utils.getMouseOverPos(frame)
  local x, y = GetCursorPosition()
  x = x / frame:GetEffectiveScale()

  local left = frame:GetLeft()
  local right = frame:GetRight()

  if x >= left and x <= right then
    y = y / frame:GetEffectiveScale()

    local top = frame:GetTop()
    local bottom = frame:GetBottom()

    if y >= bottom and y <= top then
      y = y - bottom
      y = frame:GetHeight() - y
      return x - left, y
    end

    return nil, nil
  end

  return nil, nil
end

function Utils.getlocationFontObject(mapId)
  local area = GoggleMaps.Map.Area[mapId]
  local playerFaction = UnitFactionGroup("player")
  local playerFactionId = UNIT_FACTION_TO_FACTION_ID[playerFaction]
  ---@type Font
  local fontObj
  if area.faction == 0 then
    fontObj = GameFontNormalSmall -- "|cffff6060"
  elseif playerFactionId == area.faction then
    fontObj = GameFontGreenSmall  -- "|cff20ff20"
  else
    fontObj = GameFontRedSmall    -- "|cffffff00"
  end

  return fontObj
end
