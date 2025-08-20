---@diagnostic disable: undefined-field
setfenv(1, GoggleMaps)

---@class POI
---@field name string
---@field desc string
---@field textureIndex number
---@field x number
---@field y number
---@field frame Frame

GoggleMaps.POI = {
  --- @type Frame
  frame = nil,
  --- list of POIs grouped by continent
  --- @type table<table<POI>>
  pois = {},
}

local ICON_SIZE = 16
local ATLAS_SIZE = 128

function GoggleMaps.POI:GetIcon(pos, textureIndex, poiName, poiDesc)
  local f = CreateFrame("Frame", "POIIcon" .. pos, self.frame)
  local t = f:CreateTexture()
  f.texture = t
  t:SetTexture("Interface\\Minimap\\POIIcons")
  t:SetVertexColor(1, 1, 1, 1)
  t:SetAllPoints(f)
  local size   = ICON_SIZE / ATLAS_SIZE
  local col    = Utils.mod(textureIndex, ICON_SIZE)
  local row    = math.floor(textureIndex / ICON_SIZE)
  local left   = col * size
  local right  = left + size
  local top    = row * size
  local bottom = top + size

  t:SetTexCoord(left, right, top, bottom)

  f:EnableMouse(true)

  f:SetScript("OnEnter", function()
    -- Anchor tooltip to the icon
    GameTooltip:SetOwner(f, "ANCHOR_RIGHT")

    -- Fill it with POI info
    GameTooltip:SetText(poiName, 1, 1, 1) -- white text
    -- optional: add a description
    if poiDesc and poiDesc ~= "" then
      GameTooltip:AddLine(poiDesc, 0.8, 0.8, 0.8, 1)
    end

    GameTooltip:Show()
  end)

  f:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  return f
end

---Initialised the POIs
---@param parentFrame Frame
function GoggleMaps.POI:Init(parentFrame)
  Utils.print("POI init")
  self.frame = CreateFrame("Frame", "poiFrame", parentFrame)
  self.frame:SetAllPoints()
  self.frame:SetFrameLevel(GoggleMaps.frameLevels.poi)
  self:ScanPOIs()
end

function GoggleMaps.POI:handleUpdate()
  self:DrawPOIs()
  self.frame:SetFrameLevel(GoggleMaps.frameLevels.poi)
end

function GoggleMaps.POI:ScanPOIs()
  local oldCont = GetCurrentMapContinent()
  if oldCont < 0 then
    return
  end

  local oldZone = GetCurrentMapZone()

  for continentIndex = 1, table.getn(Utils.GetContinents()) do
    local pois = {}
    self.pois[continentIndex] = pois
    SetMapZoom(continentIndex)
    local mapId = continentIndex * 1000

    local name, desc, textureIndex, poiX, poiY
    local numPois = GetNumMapLandmarks()

    for n = 1, numPois do
      name, desc, textureIndex, poiX, poiY = GetMapLandmarkInfo(n)

      if name then
        local x, y = Utils.GetWorldPos(mapId, poiX * 100, poiY * 100)
        ---@type POI
        local poi = {
          name = name,
          desc = desc,
          textureIndex = textureIndex,
          x = x,
          y = y,
          frame = self:GetIcon(mapId + n, textureIndex, name, desc)
        }
        Utils.print("POI: %s %d, %.2f, %.2f", name, textureIndex, poiX, poiY)
        Utils.print("POI: %s %d, %.2f, %.2f", name, textureIndex, x, y)
        table.insert(pois, poi)
      end
    end
    Utils.print("Found %d POIs for continent %d", table.getn(pois), continentIndex)
  end
  -- Restore
  SetMapZoom(oldCont, oldZone)
end

function GoggleMaps.POI:DrawPOIs()
  local scale = GoggleMaps.Map.scale
  local clipW = GoggleMaps.Map.size.width
  local clipH = GoggleMaps.Map.size.height
  local x, y
  for continentIndex in ipairs(GoggleMaps.Map.MapInfo) do
    for k, v in ipairs(self.pois[continentIndex]) do
      ---@type POI
      local poi = v

      x = ((poi.x - GoggleMaps.Map.position.x) * scale + clipW / 2) - ICON_SIZE / 2
      y = ((poi.y - GoggleMaps.Map.position.y) * scale + clipH / 2) - ICON_SIZE / 2

      Utils.ClipFrame(poi.frame, x, y, ICON_SIZE, ICON_SIZE, clipW, clipH)
    end
  end
end
