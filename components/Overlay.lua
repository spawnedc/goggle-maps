setfenv(1, GoggleMaps)

GoggleMaps.Overlay = {
  ---@type Frame
  parentFrame = nil,
  ---@type table<table<Frame>>
  frames = {},
  options = {
    maxZonesToDraw = 5,
  },
  --- The list of zone mapIds to draw. Shouldn't exceed options.maxZonesToDraw
  zonesToDraw = {},
  zonesToClear = {}
}

function GoggleMaps.Overlay:Init(parentFrame)
  Utils.print("Overlay init")
  self.parentFrame = parentFrame
  self:UpdateOverlays()
end

function GoggleMaps.Overlay:handleUpdate()
  self:UpdateOverlays()
end

function GoggleMaps.Overlay:UpdateOverlays()
  for _, mapId in ipairs(self.zonesToClear) do
    local overlays = self.frames[mapId]
    if overlays then
      for overlayName, overlayFrame in pairs(overlays) do
        overlayFrame:Hide()
      end
    end
    self.frames[mapId] = nil
  end
  self.zonesToClear = {}

  local mapId
  -- looping in reverse, so that the first mapId is updated last, so it appears on top of others
  for i = table.getn(self.zonesToDraw), 1, -1 do
    mapId = self.zonesToDraw[i]
    self:UpdateOverlay(mapId)
  end
end

---Adds a mapId to be drawn on the map as an overlay
---@param mapId number
function GoggleMaps.Overlay:AddMapIdToZonesToDraw(mapId)
  local idList = self.zonesToDraw
  -- Remove if already present
  for i = 1, table.getn(idList) do
    if idList[i] == mapId then
      local removedMapId = table.remove(idList, i)
      -- This forces the frames to be hidden and re-shown so the mapId we added just now can appear on top.
      -- SetFrameLevel and/or SetFrameStrata doesn't seem to be working. Send help!
      table.insert(self.zonesToClear, removedMapId)
      break
    end
  end

  -- Insert at the front
  table.insert(idList, 1, mapId)

  -- If list exceeds limit, remove last
  if table.getn(idList) > self.options.maxZonesToDraw then
    local removedMapId = table.remove(idList) -- removes last by default
    Utils.print("Adding %s to the clear list", removedMapId)
    table.insert(self.zonesToClear, removedMapId)
  end
end

---Gets the next available overlay frames
---@param mapId number
---@param overlayName string
---@param levelAdd number?
---@return Frame
function GoggleMaps.Overlay:GetAvailableOverlayFrame(mapId, overlayName, levelAdd)
  if not self.frames[mapId] then
    self.frames[mapId] = {}
  end

  local overlayFrame = self.frames[mapId][overlayName]
  if not overlayFrame then
    local frameName = string.format("Overlay-%s-%s", mapId, overlayName)
    overlayFrame = CreateFrame("Frame", frameName, self.parentFrame)

    local t = overlayFrame:CreateTexture(nil, 'BACKGROUND')
    t:SetVertexColor(1, 1, 1, 1)
    t:SetBlendMode("BLEND")
    t:SetAllPoints(overlayFrame)
    overlayFrame.texture = t
    self.frames[mapId][overlayName] = overlayFrame
  end

  overlayFrame:SetFrameLevel(GoggleMaps.Map.frameLevel + (levelAdd or 0))

  return overlayFrame
end

--- Clip a frame to the map and set position (top left), size and texture coords
--- Width and height are scaled by base (zone) scale
---@param frame Frame
---@param xPos number
---@param yPos number
---@param frameWidth number
---@param frameHeight number
---@return boolean
function GoggleMaps.Overlay:ClipFrame(frame, xPos, yPos, frameWidth, frameHeight)
  -- Each world unit maps to a pixel, so frameWidth * scale == size in pixels
  local Map = GoggleMaps.Map
  local scale = Map.scale
  local clipW = Map.size.width
  local clipH = Map.size.height
  local x = (xPos - Map.position.x) * scale + clipW / 2
  local y = (yPos - Map.position.y) * scale + clipH / 2
  local baseWidth = frameWidth * scale
  local baseHeight = frameHeight * scale

  return Utils.ClipFrame(frame, x, y, baseWidth, baseHeight, clipW, clipH)
end

---Initialises the continent overlays
---@param mapId number
function GoggleMaps.Overlay:UpdateOverlay(mapId)
  if mapId == nil then
    return
  end
  local zone = GoggleMaps.Map.Area[mapId]
  if zone == nil then
    Utils.print("Zone not found: %s", mapId)
    return
  end
  local overlays = GoggleMaps.Map.Overlay[zone.overlay]
  if overlays == nil then
    Utils.log(string.format("Zone overlay not found: %s %s", zone.name, zone.overlay))
    return
  end
  local TEXTURE_SIZE = 256
  local DETAIL_FRAME_WIDTH = 1002
  local DETAIL_FRAME_HEIGHT = 668
  local textureFolder = zone.overlay
  local baseTexturePath = "Interface\\WorldMap\\" .. textureFolder .. "\\"
  local textureFileHeight, textureFileWidth, texturePixelHeight, texturePixelWidth
  local zoneScale = zone.scale / 10

  for textureName, overlayData in pairs(overlays) do
    local texturePath = baseTexturePath .. textureName

    local offsetX, offsetY, fullTextureWidth, fullTextureHeight, mode = Utils.splitString(overlayData, ",")

    offsetX = tonumber(offsetX) or 0
    offsetY = tonumber(offsetY) or 0
    fullTextureWidth = tonumber(fullTextureWidth) or 0
    fullTextureHeight = tonumber(fullTextureHeight) or 0

    local numTextureCols = math.ceil(fullTextureWidth / TEXTURE_SIZE)
    local numTextureRows = math.ceil(fullTextureHeight / TEXTURE_SIZE)
    local textureIndex = 1

    for textureRowIndex = 1, numTextureRows do
      if textureRowIndex < numTextureRows then
        texturePixelHeight = TEXTURE_SIZE
        textureFileHeight = TEXTURE_SIZE
      else
        texturePixelHeight = Utils.mod(fullTextureHeight, TEXTURE_SIZE)
        if texturePixelHeight == 0 then
          texturePixelHeight = TEXTURE_SIZE
        end
        textureFileHeight = 16
        while textureFileHeight < texturePixelHeight do
          textureFileHeight = textureFileHeight * 2
        end
      end

      for textureColIndex = 1, numTextureCols do
        if textureColIndex < numTextureCols then
          texturePixelWidth = TEXTURE_SIZE
          textureFileWidth = TEXTURE_SIZE
        else
          texturePixelWidth = Utils.mod(fullTextureWidth, TEXTURE_SIZE)
          if texturePixelWidth == 0 then
            texturePixelWidth = TEXTURE_SIZE
          end
          textureFileWidth = 16
          while textureFileWidth < texturePixelWidth do
            textureFileWidth = textureFileWidth * 2
          end
        end

        local f = self:GetAvailableOverlayFrame(mapId, textureName .. tostring(textureIndex))

        local xPos = (offsetX + (textureColIndex - 1) * TEXTURE_SIZE) / DETAIL_FRAME_WIDTH * 100
        local yPos = (offsetY + (textureRowIndex - 1) * TEXTURE_SIZE) / DETAIL_FRAME_HEIGHT * 100

        local wx, wy = Utils.GetWorldPos(mapId, xPos, yPos)
        local width = textureFileWidth * zoneScale
        local height = textureFileHeight * zoneScale

        if self:ClipFrame(f, wx, wy, width, height) then
          local finalTexturePath = mode and texturePath or texturePath .. textureIndex

          f.texture:SetTexture(finalTexturePath)
        end

        textureIndex = textureIndex + 1
      end
    end
  end
end
