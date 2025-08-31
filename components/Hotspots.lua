setfenv(1, GoggleMaps)

---@class Hotspot
---@field name string
---@field mapId number
---@field worldX1 number
---@field worldX2 number
---@field worldY1 number
---@field worldY2 number

GoggleMaps.Hotspots = {
  spots = {},
  cities = {}
}

function GoggleMaps.Hotspots:Init()
  Utils.debug("InitHotspots")
  local hotspots = GoggleMaps.Map.Hotspots
  local spots = self.spots
  local cities = self.cities

  for mapId, hotspotRects in pairs(hotspots) do
    local hotspotList = { Utils.splitString(hotspotRects, "~") }
    local contName, contX, contY = Utils.GetWorldContinentInfo(Utils.getContinentId(mapId))

    for _, hotspot in pairs(hotspotList) do
      local mapX, mapY, width, height, name = Utils.UnpackLocationRect(hotspot)

      local zoneInfo = GoggleMaps.Map.Area[mapId]

      if not zoneInfo then
        break
      end


      local worldX, worldY, worldX2, worldY2

      -- pre-calculate positions
      if zoneInfo.isCity or zoneInfo.isInstance or zoneInfo.isRaid then
        Utils.debug("%s %sx %s", contName, contX, contY)
        worldX = mapX + contX
        worldY = contY - (mapY + height)
        worldX2 = worldX + width
        worldY2 = contY - mapY
      else
        worldX, worldY = Utils.GetWorldPos(mapId, mapX, mapY)
        worldX2, worldY2 = Utils.GetWorldPos(mapId, mapX + width, mapY + height)
      end

      --- @type Hotspot
      local spot = {
        name = name,
        mapId = mapId,
        worldX1 = worldX,
        worldY1 = worldY,
        worldX2 = worldX2,
        worldY2 = worldY2
      }

      if zoneInfo.isCity then
        table.insert(cities, spot)
      else
        table.insert(spots, spot)
      end
    end
  end

  GMapsDebug:AddItem("Current hotspot", "-")
  GMapsDebug:AddItem("Zone name", "-")
  GMapsDebug:AddItem("Hotspot name", "-")
  GMapsDebug:AddItem("Hotspot coords1", "-")
  GMapsDebug:AddItem("Hotspot coords2", "-")
end

---Checks if the given coordinates belong to any hotspots. If so, returns the mapId
---@param worldX number
---@param worldY number
---@return number | nil newMapId
function GoggleMaps.Hotspots:CheckWorldHotspots(worldX, worldY)
  local cities = self.cities
  local spots = self.spots
  local newMapId = nil

  newMapId = self:CheckWorldHotspotsType(worldX, worldY, cities)

  if newMapId then
    return newMapId
  end

  newMapId = self:CheckWorldHotspotsType(worldX, worldY, spots)

  return newMapId
end

---Checks world zone hotspots type. This is very fast.
---@param worldX number
---@param worldY number
---@param spots table<string>
function GoggleMaps.Hotspots:CheckWorldHotspotsType(worldX, worldY, spots)
  for _, spot in ipairs(spots) do
    if worldX >= spot.worldX1 and worldX <= spot.worldX2 and worldY >= spot.worldY1 and worldY <= spot.worldY2 then
      GMapsDebug:UpdateItem("Current hotspot", spot.mapId)
      local zoneName = GoggleMaps.Map.Area[spot.mapId].name
      GMapsDebug:UpdateItem("Zone name", zoneName)
      GMapsDebug:UpdateItem("Hotspot name", spot.name)
      GMapsDebug:UpdateItem("Hotspot coords1", string.format("%.2f, %2.f", spot.worldX1, spot.worldY1))
      GMapsDebug:UpdateItem("Hotspot coords2", string.format("%.2f, %2.f", spot.worldX2, spot.worldY2))
      return spot.mapId
    end
  end

  GMapsDebug:UpdateItem("Current hotspot", "-")
  GMapsDebug:UpdateItem("Zone name", "-")
  GMapsDebug:UpdateItem("Hotspot name", "-")
  GMapsDebug:UpdateItem("Hotspot coords1", "-")
  GMapsDebug:UpdateItem("Hotspot coords2", "-")
  return nil
end
