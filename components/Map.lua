setfenv(1, GoggleMaps)

local FRAME_WIDTH = 1024
local FRAME_HEIGHT = 768

local DETAIL_FRAME_WIDTH = 1002
local DETAIL_FRAME_HEIGHT = 668

-- These represent continents and their blocks (4x3 in a 1-dimentional array)
-- Only blocks with 1s will be rendered, 0s will be ignored
local CONTINENT_BLOCKS = {
  [1] = { 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0 },
  [2] = { 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0 },
}

GoggleMaps.Map = {
  Area = {},
  Overlay = {},
  MapInfo = {
    [1] = {
      Name = "Kalimdor",
      FileName = "Kalimdor",
      X = 0,
      Y = 500,
    },
    [2] = {
      Name = "Eastern Kingdoms",
      FileName = "Azeroth",
      X = 3784,
      Y = -200,
    },
  },
  ---@type Frame
  frame = nil,
  ---@type table<table<Frame>>
  continentFrames = {},
  ---@type Frame
  zoneFrame = nil,
  ---@type table<table<Frame>>
  zoneFrames = {},
  initialised = false,
  isDragging = false,
  isZooming = false,
  scale = 0.5,
  maxScale = 10,
  minScale = 0.1,
  effectiveScale = 0.5,
  position = {
    x = 800,
    y = 500
  },
  size = {
    width = DETAIL_FRAME_WIDTH,
    height = DETAIL_FRAME_HEIGHT
  },
  scroll = {
    x = 0,
    y = 0
  },

  --- Map id of the current zone. This changes when mouse moves through the map.
  mapId = 0,
  --- Map id of the zone that player is in.
  realMapId = 0,
  --- For easy access to map ids from a zone name. This is useful when getting the player's zone's map id using GetRealZoneText()
  --- @type table<number>
  zoneNameToMapId = {},
  --- Used for getting a zone's mapId from continent id and its index
  --- @type table<table<number>>
  continentZoneToMapId = {}
}

---Initialises the map
---@param parentFrame Frame
function GoggleMaps.Map:Init(parentFrame)
  GMapsDebug:AddItem("zoom", self.scale, Utils.numberFormatter(2))
  GMapsDebug:AddItem("Map pos", self.position, Utils.positionFormatter)
  GMapsDebug:AddItem("Map size", self.size, Utils.sizeFormatter)

  self.frame = parentFrame
  self.frame:EnableMouse(true)
  self.frame:EnableMouseWheel(true)

  self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

  self.frame:SetScript("OnMouseWheel", function() self:handleZoom() end)
  self.frame:SetScript("OnMouseDown", function() self:handleMouseDown() end)
  self.frame:SetScript("OnMouseUp", function() self.isDragging = false end)
  self.frame:SetScript("OnEvent", function() self:handleEvent() end)

  self:InitTables()

  self.mapId = self.zoneNameToMapId[GetRealZoneText()]
  self.realMapId = self.mapId

  GoggleMaps.Overlay:AddMapIdToZonesToDraw(self.realMapId)
  GoggleMaps.Overlay:AddMapIdToZonesToDraw(self.mapId)

  GMapsDebug:AddItem("Current zone", GetRealZoneText())
  GMapsDebug:AddItem("Current mapId", self.realMapId)
  GMapsDebug:AddItem("Fake mapId", self.mapId)
  GMapsDebug:AddItem("Mouse winpos", { x = 0, y = 0 }, Utils.positionFormatter)
  GMapsDebug:AddItem("Mouse world pos", { x = 0, y = 0 }, Utils.positionFormatter)

  self:InitContinents()
end

function GoggleMaps.Map:InitTables()
  Utils.print("InitTables")
  self.zoneNameToMapId, self.continentZoneToMapId = Utils.GetZoneNameToMapId()
end

function GoggleMaps.Map:handleZoom()
  self:handleMouseDown(true)
  self.isDragging = false

  -- scroll.x and scroll.y are calculated in HandleMouseDown()
  local x = self.scroll.x
  local y = self.scroll.y

  local left = this:GetLeft()
  local top = this:GetTop()
  local map = self

  local originalX = map.position.x + (x - left - map.size.width / 2) / map.scale
  local originalY = map.position.y + (top - y - map.size.height / 2) / map.scale

  local value = arg1
  local scale = self.scale
  if value < 0 then
    value = value * .76923
  end

  self.scale = math.max(scale + value * scale * .3, self.minScale)
  self.scale = math.min(self.scale, self.maxScale)

  local newX = map.position.x + (x - left - map.size.width / 2) / map.scale
  local newY = map.position.y + (top - y - map.size.height / 2) / map.scale

  map.position.x = map.position.x + originalX - newX
  map.position.y = map.position.y + originalY - newY

  GMapsDebug:UpdateItem("zoom", scale)
  GMapsDebug:UpdateItem("Map pos", self.position)

  self:MoveMap()
end

---Handles the mouse down event
---@param force boolean?
function GoggleMaps.Map:handleMouseDown(force)
  if force or arg1 == "LeftButton" then
    local effectiveScale = self.frame:GetEffectiveScale()
    self.effectiveScale = effectiveScale

    local x, y = GetCursorPosition()
    x = x / effectiveScale
    y = y / effectiveScale

    self.scroll.x = x
    self.scroll.y = y
    self.isDragging = true
  end
end

function GoggleMaps.Map:handleEvent()
  if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
    Utils.print('ZONE_CHANGED_NEW_AREA')
    self.realMapId = self.zoneNameToMapId[GetRealZoneText()]
    self.mapId = self.realMapId
    Utils.setCurrentMap(self.realMapId)
    GoggleMaps.Overlay:AddMapIdToZonesToDraw(self.realMapId)
    GMapsDebug:UpdateItem("Current zone", GetRealZoneText())
    GMapsDebug:UpdateItem("Current mapId", self.realMapId)
    GMapsDebug:UpdateItem("Fake mapId", self.mapId)
  end
end

function GoggleMaps.Map:InitContinents()
  Utils.print('InitContinents')

  local texturePath

  for continentIndex in ipairs(Utils.GetContinents()) do
    local continentBlocks = CONTINENT_BLOCKS[continentIndex]
    self.continentFrames[continentIndex] = {}

    local mapInfo = self.MapInfo[continentIndex]
    local mapFileName = mapInfo.FileName

    for blockIndex, block in ipairs(continentBlocks) do
      if block ~= 0 then
        texturePath = mapFileName .. "\\" .. mapFileName .. blockIndex
        local frameName = string.format("Continent-%s-%d", mapFileName, blockIndex)
        local continentFrame = self:CreateFrameWithTexture(frameName, texturePath)
        continentFrame:SetFrameLevel(GoggleMaps.frameLevels.continent)
        self.continentFrames[continentIndex][blockIndex] = continentFrame
      end
    end
  end
end

function GoggleMaps.Map:InitZones()
  Utils.print('InitZones')
  self.zoneFrame = CreateFrame("Frame", nil, self.frame)
  self.zoneFrame:SetAllPoints(self.frame)
  self.zoneFrame:SetFrameLevel(GoggleMaps.frameLevels.city)
  self.zoneFrames = {}

  for i = 1, 12 do
    self.zoneFrames[i] = self:CreateFrameWithTexture("zone-" .. i, nil, self.zoneFrame)
  end
end

function GoggleMaps.Map:UpdateZoneTextures()
  local mapFileName = GetMapInfo()
  for i = 1, 12 do
    self.zoneFrames[i].texture:SetTexture("Interface\\WorldMap\\" .. mapFileName .. "\\" .. mapFileName .. i)
  end
  self:MoveZones()
end

---Creates a frame with a texture attached
---@param frameName string
---@param texturePath string | nil
---@param parentFrame Frame?
---@return Frame
function GoggleMaps.Map:CreateFrameWithTexture(frameName, texturePath, parentFrame)
  parentFrame = parentFrame or self.frame
  local frame = CreateFrame("Frame", frameName, parentFrame)

  local t = frame:CreateTexture()
  t:SetAllPoints(frame)
  if texturePath then
    t:SetTexture("Interface\\WorldMap\\" .. texturePath)
  end

  frame.texture = t

  return frame
end

---Handles the map movement
---@param xPos? number
---@param yPos? number
function GoggleMaps.Map:MoveMap(xPos, yPos)
  if xPos and yPos then
    self.position.x = xPos
    self.position.y = yPos
  else
    self.effectiveScale = self.frame:GetEffectiveScale()

    local cursorX, cursorY = GetCursorPosition()

    cursorX = cursorX / self.effectiveScale
    cursorY = cursorY / self.effectiveScale

    local x = cursorX - self.scroll.x
    local y = cursorY - self.scroll.y

    self.scroll.x = cursorX
    self.scroll.y = cursorY

    local mx = x / self.scale
    local my = y / self.scale

    self.position.x = self.position.x - mx
    self.position.y = self.position.y + my
  end
  GMapsDebug:UpdateItem("Map pos", self.position)

  self:MoveContinents()
  self:MoveZones()
end

function GoggleMaps.Map:MoveContinents()
  for continentIndex in ipairs(Utils.GetContinents()) do
    self:MoveZoneTiles(continentIndex, continentIndex * 1000, self.continentFrames[continentIndex])
  end
end

function GoggleMaps.Map:MoveZones()
  if not self.mapId then
    return
  end
  local isCity = GoggleMaps.Map.Area[self.mapId].isCity
  if isCity then
    local continentIndex = Utils.getContinentId(self.mapId)
    self:MoveZoneTiles(continentIndex, self.mapId, self.zoneFrames)
  else
    for i = 1, 12 do
      self.zoneFrames[i]:Hide()
    end
  end
end

---Moves zone tiles
---@param continentIndex number
---@param zoneId number
---@param frames Frame[]
function GoggleMaps.Map:MoveZoneTiles(continentIndex, zoneId, frames)
  local row, col = 0, 0
  local frameX, frameY
  local NUM_COLUMNS = 4
  local NUM_ROWS = 3
  local _, xPos, yPos, zoneWidth, zoneHeight = Utils.GetWorldZoneInfo(continentIndex, zoneId)
  local frameWidth = zoneWidth * FRAME_WIDTH / DETAIL_FRAME_WIDTH / NUM_COLUMNS
  local frameHeight = zoneHeight * FRAME_HEIGHT / DETAIL_FRAME_HEIGHT / NUM_ROWS

  local scale = self.scale
  local clipW = self.size.width
  local clipH = self.size.height
  local x = (xPos - self.position.x) * scale + clipW / 2
  local y = (yPos - self.position.y) * scale + clipH / 2
  local baseWidth = frameWidth * scale
  local baseHeight = frameHeight * scale

  for i = 1, NUM_COLUMNS * NUM_ROWS do
    local frame = frames[i]
    if frame then
      row = Utils.mod(i - 1, NUM_COLUMNS)
      col = math.floor((i - 1) / NUM_COLUMNS)

      frameX = row * baseWidth + x
      frameY = col * baseHeight + y

      Utils.ClipFrame(frame, frameX, frameY, baseWidth, baseHeight, clipW, clipH)
    end
  end
end

function GoggleMaps.Map:handleUpdate()
  if self.isDragging then
    self:MoveMap()
  else
    local player = GoggleMaps.Player
    if player.isMoving then
      local playerPos = player.position
      local worldX, worldY = Utils.GetWorldPos(self.realMapId, playerPos.x, playerPos.y)

      self:MoveMap(worldX, worldY)
    end

    local winx, winy = Utils.getMouseOverPos(self.frame)
    if winx and winy then
      local worldX, worldY = self:FramePosToWorldPos(winx, winy)
      local newMapId = GoggleMaps.Hotspots:CheckWorldHotspots(worldX, worldY)
      if newMapId and self.mapId ~= newMapId then
        self.mapId = newMapId
        Utils.setCurrentMap(self.mapId)
        GoggleMaps.Overlay:AddMapIdToZonesToDraw(self.realMapId)
        GoggleMaps.Overlay:AddMapIdToZonesToDraw(self.mapId)
      end
      GMapsDebug:UpdateItem("Mouse winpos", { x = winx, y = winy })
      GMapsDebug:UpdateItem("Mouse world pos", { x = worldX, y = worldY })
    elseif self.mapId ~= self.realMapId then
      -- User is not hovering over the map. Let's revert to realMapId and move the map
      self.mapId = self.realMapId
      Utils.setCurrentMap(self.mapId)
      GoggleMaps.Overlay:AddMapIdToZonesToDraw(self.realMapId)
    end
    self:UpdateZoneTextures()
    self.zoneFrame:SetFrameLevel(GoggleMaps.frameLevels.city)
  end


  GMapsDebug:UpdateItem("Map size", self.size)
  GMapsDebug:UpdateItem("Current zone", GetRealZoneText())
  GMapsDebug:UpdateItem("Current mapId", self.realMapId)
  GMapsDebug:UpdateItem("Fake mapId", self.mapId)
end

--- Convert frame (top left) to world positions
---@param x number
---@param y number
---@return number, number worldPos world positions
function GoggleMaps.Map:FramePosToWorldPos(x, y)
  x = self.position.x + (x - self.size.width / 2) / self.scale
  y = self.position.y + (y - self.size.height / 2) / self.scale
  return x, y
end
