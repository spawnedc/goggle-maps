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
  ---@type Frame
  instanceFrame = nil,
  ---@type table<table<Frame>>
  instanceFrames = {},
  initialised = false,
  isDragging = false,
  isZooming = false,
  scale = 0.5,
  previousScale = 0.5,
  maxScale = 300,
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
  --- For easy access to map ids from a zone name. This is useful when getting the player's zone's map id using GetZoneText()
  --- @type table<number>
  zoneNameToMapId = {},

  previousZone = 0
}

function GoggleMaps.Map:InitDB(force)
  if GoggleMapsDB.Map == nil then
    GoggleMapsDB.Map = {
      scale = 0.5,
      previousScale = 0.5
    }
  end
  self.scale = GoggleMapsDB.Map.scale

  if force then
    self:MoveToPlayer()
  end
end

---Initialises the map
---@param parentFrame Frame
function GoggleMaps.Map:Init(parentFrame)
  GMapsDebug:AddItem("zoom", self.scale, Utils.numberFormatter(2))
  GMapsDebug:AddItem("zoom (ex)", self.previousScale, Utils.numberFormatter(2))
  GMapsDebug:AddItem("Map pos", self.position, Utils.positionFormatter)
  GMapsDebug:AddItem("Map size", self.size, Utils.sizeFormatter)

  self:InitDB()

  self.frame = parentFrame
  self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  self.frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

  self:EnableInteraction()
  self.frame:SetScript("OnEvent", function() self:handleEvent() end)

  self:InitTables()

  self.mapId = self.zoneNameToMapId[GetZoneText()]
  self.realMapId = self.mapId

  GoggleMaps.Overlay:AddMapIdToZonesToDraw(self.realMapId)
  GoggleMaps.Overlay:AddMapIdToZonesToDraw(self.mapId)

  GMapsDebug:AddItem("Current zone", GetZoneText())
  GMapsDebug:AddItem("Current mapId", self.realMapId)
  GMapsDebug:AddItem("Fake mapId", self.mapId)
  GMapsDebug:AddItem("Mouse winpos", { x = 0, y = 0 }, Utils.positionFormatter)
  GMapsDebug:AddItem("Mouse world pos", { x = 0, y = 0 }, Utils.positionFormatter)
  GMapsDebug:AddItem("Mouse zone pos", { x = 0, y = 0 }, Utils.positionFormatter)

  self:InitContinents()
end

function GoggleMaps.Map:EnableInteraction()
  self.frame:EnableMouse(true)
  self.frame:EnableMouseWheel(true)

  self.frame:SetScript("OnMouseWheel", function() self:handleZoom() end)
  self.frame:SetScript("OnMouseDown", function() self:handleMouseDown() end)
  self.frame:SetScript("OnMouseUp", function() self.isDragging = false end)
end

function GoggleMaps.Map:DisableInteraction()
  self.frame:EnableMouse(false)
  self.frame:EnableMouseWheel(false)

  self.frame:SetScript("OnMouseWheel", nil)
  self.frame:SetScript("OnMouseDown", nil)
  self.frame:SetScript("OnMouseUp", nil)
end

function GoggleMaps.Map:InitTables()
  Utils.debug("InitTables")
  self.zoneNameToMapId = Utils.GetZoneNameToMapId()
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

  GoggleMapsDB.Map.scale = self.scale

  local newX = map.position.x + (x - left - map.size.width / 2) / map.scale
  local newY = map.position.y + (top - y - map.size.height / 2) / map.scale

  map.position.x = map.position.x + originalX - newX
  map.position.y = map.position.y + originalY - newY

  GMapsDebug:UpdateItem("zoom", scale)
  GMapsDebug:UpdateItem("zoom (ex)", self.previousScale)
  GMapsDebug:UpdateItem("Map pos", self.position)

  self:MoveMap()
end

---Handles the mouse down event
---@param force boolean?
function GoggleMaps.Map:handleMouseDown(force)
  if force or arg1 == "LeftButton" then
    local effectiveScale = self.frame:GetEffectiveScale()

    local x, y = GetCursorPosition()
    x = x / effectiveScale
    y = y / effectiveScale

    self.scroll.x = x
    self.scroll.y = y
    self.isDragging = true
  end
end

---@diagnostic disable-next-line: duplicate-set-field
function GoggleMaps.Map:handleEvent()
  if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
    Utils.debug('ZONE_CHANGED_NEW_AREA')
    self.realMapId = self.zoneNameToMapId[GetZoneText()]
    self.mapId = self.realMapId
    Utils.debug("Name: %s, mapId: %s", GetZoneText(), tostring(self.realMapId))
    Utils.setCurrentMap(self.realMapId, "ZONE_CHANGED_NEW_AREA")

    if self.realMapId ~= self.previousZone then
      self.previousZone = self.realMapId
      if Utils.IsInstanceMap(self.realMapId) then
        self.previousScale = self.scale + 0.000001 - 0.000001
        self.scale = 300
      else
        self.scale = self.previousScale + 0.000001 - 0.000001
      end
    end
    GoggleMaps.Overlay:AddMapIdToZonesToDraw(self.realMapId)
    GMapsDebug:UpdateItem("zoom", self.scale)
    GMapsDebug:UpdateItem("zoom (ex)", self.previousScale)
    GMapsDebug:UpdateItem("Current zone", GetZoneText())
    GMapsDebug:UpdateItem("Current mapId", self.realMapId)
    GMapsDebug:UpdateItem("Fake mapId", self.mapId)
  end
end

function GoggleMaps.Map:InitContinents()
  Utils.debug('InitContinents')

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
  Utils.debug('InitZones')
  self.zoneFrame = CreateFrame("Frame", nil, self.frame)
  self.zoneFrame:SetAllPoints(self.frame)
  self.zoneFrame:SetFrameLevel(GoggleMaps.frameLevels.city)
  self.zoneFrames = {}

  for i = 1, 12 do
    self.zoneFrames[i] = self:CreateFrameWithTexture("zone-" .. i, nil, self.zoneFrame)
  end
end

function GoggleMaps.Map:InitInstances()
  Utils.debug('InitInstances')
  self.instanceFrame = CreateFrame("Frame", nil, self.frame)
  self.instanceFrame:SetAllPoints(self.frame)
  self.instanceFrame:SetFrameLevel(GoggleMaps.frameLevels.instance)
  self.instanceFrames = {}

  for i = 1, 12 do
    self.instanceFrames[i] = self:CreateFrameWithTexture("instance-" .. i, nil, self.instanceFrame)
  end
end

function GoggleMaps.Map:UpdateZoneTextures()
  local mapFileName
  local area = GoggleMaps.Map.Area[self.mapId]
  if area.isCity then
    mapFileName = area.overlay
  else
    local realArea = GoggleMaps.Map.Area[self.realMapId]
    if realArea.isCity then
      mapFileName = realArea.overlay
    end
  end

  if not mapFileName then
    return
  end
  for i = 1, 12 do
    self.zoneFrames[i].texture:SetTexture("Interface\\WorldMap\\" .. mapFileName .. "\\" .. mapFileName .. i)
  end
  self:MoveZones()
end

function GoggleMaps.Map:UpdateInstanceTextures()
  local mapFileName
  local realArea = GoggleMaps.Map.Area[self.realMapId]
  if realArea.isInstance or realArea.isRaid then
    mapFileName = realArea.overlay
  end

  if not mapFileName then
    return
  end
  for i = 1, 12 do
    self.instanceFrames[i].texture:SetTexture("Interface\\WorldMap\\" .. mapFileName .. "\\" .. mapFileName .. i)
  end
  self:MoveInstances()
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
    local effectiveScale = self.frame:GetEffectiveScale()

    local cursorX, cursorY = GetCursorPosition()

    cursorX = cursorX / effectiveScale
    cursorY = cursorY / effectiveScale

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
  self:MoveInstances()
end

function GoggleMaps.Map:MoveContinents()
  for continentIndex in ipairs(Utils.GetContinents()) do
    self:MoveZoneTiles(continentIndex * 1000, self.continentFrames[continentIndex])
  end
end

function GoggleMaps.Map:MoveZones()
  if not self.mapId then
    return
  end
  local area = GoggleMaps.Map.Area[self.mapId]
  if area.isCity then
    self:MoveZoneTiles(self.mapId, self.zoneFrames)
  else
    local realArea = GoggleMaps.Map.Area[self.realMapId]
    if realArea.isCity then
      self:MoveZoneTiles(self.realMapId, self.zoneFrames)
    else
      for i = 1, 12 do
        self.zoneFrames[i]:Hide()
      end
    end
  end
end

function GoggleMaps.Map:MoveInstances()
  if not self.mapId then
    return
  end
  local realArea = GoggleMaps.Map.Area[self.realMapId]
  if realArea.isInstance or realArea.isRaid then
    self:MoveZoneTiles(self.realMapId, self.instanceFrames)
  else
    for i = 1, 12 do
      self.instanceFrames[i]:Hide()
    end
  end
end

---Moves zone tiles
---@param mapId number
---@param frames Frame[]
function GoggleMaps.Map:MoveZoneTiles(mapId, frames)
  local row, col = 0, 0
  local frameX, frameY
  local NUM_COLUMNS = 4
  local NUM_ROWS = 3
  local _, xPos, yPos, zoneWidth, zoneHeight = Utils.GetWorldZoneInfo(mapId)
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

function GoggleMaps.Map:MoveToPlayer()
  local player = GoggleMaps.Player
  local playerPos = player.position
  local worldX, worldY = Utils.GetWorldPos(self.realMapId, playerPos.x, playerPos.y)

  self:MoveMap(worldX, worldY)
end

function GoggleMaps.Map:handleUpdate()
  if self.isDragging then
    self:MoveMap()
  else
    local player = GoggleMaps.Player
    if player.isMoving then
      self:MoveToPlayer()
    end

    local winx, winy = Utils.getMouseOverPos(self.frame)
    if winx and winy then
      local worldX, worldY = Utils.FramePosToWorldPos(winx, winy)
      local newMapId = GoggleMaps.Hotspots:CheckWorldHotspots(worldX, worldY)
      if newMapId and self.mapId ~= newMapId then
        self.mapId = newMapId
        Utils.setCurrentMap(self.mapId)
        GoggleMaps.Overlay:AddMapIdToZonesToDraw(self.realMapId)
        GoggleMaps.Overlay:AddMapIdToZonesToDraw(self.mapId)
      end
      local zoneX, zoneY = Utils.GetZonePosFromWorldPos(self.mapId, worldX, worldY)
      GMapsDebug:UpdateItem("Mouse winpos", { x = winx, y = winy })
      GMapsDebug:UpdateItem("Mouse world pos", { x = worldX, y = worldY })
      GMapsDebug:UpdateItem("Mouse zone pos", { x = zoneX, y = zoneY })
    elseif self.mapId ~= self.realMapId then
      -- User is not hovering over the map. Let's revert to realMapId and move the map
      self.mapId = self.realMapId
      Utils.setCurrentMap(self.realMapId)
      GoggleMaps.Overlay:AddMapIdToZonesToDraw(self.realMapId)
    end
    self:UpdateZoneTextures()
    self.zoneFrame:SetFrameLevel(GoggleMaps.frameLevels.city)
    self:UpdateInstanceTextures()
    self.instanceFrame:SetFrameLevel(GoggleMaps.frameLevels.instance)
  end


  GMapsDebug:UpdateItem("Map size", self.size)
  GMapsDebug:UpdateItem("Current zone", GetZoneText())
  GMapsDebug:UpdateItem("Current mapId", self.realMapId)
  GMapsDebug:UpdateItem("Fake mapId", self.mapId)
end
