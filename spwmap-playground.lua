setfenv(1, SpwMap)

local UI = VanillaUI

local FRAME_WIDTH = 1024
local FRAME_HEIGHT = 768

---@type Frame
SpwMap.frame = nil
---@type Frame
SpwMap.mapFrame = nil
---@type table<Frame>
SpwMap.continentFrames = {}

function SpwMap:handleZoom()
  SpwMap:HandleMouseDown()
  SpwMap.Map.isDragging = false

  -- scroll.x and scroll.y are calculated in HandleMouseDown()
  local x = SpwMap.Map.scroll.x
  local y = SpwMap.Map.scroll.y

  local left = this:GetLeft()
  local top = this:GetTop()
  local map = SpwMap.Map

  local originalX = map.position.x + (x - left - map.size.width / 2) / map.scale
  local originalY = map.position.y + (top - y - map.size.height / 2) / map.scale

  local value = arg1
  local scale = SpwMap.Map.scale
  if value < 0 then
    value = value * .76923
  end

  SpwMap.Map.scale = math.max(scale + value * scale * .3, SpwMap.Map.minScale)
  SpwMap.Map.scale = math.min(SpwMap.Map.scale, SpwMap.Map.maxScale)

  local newX = map.position.x + (x - left - map.size.width / 2) / map.scale
  local newY = map.position.y + (top - y - map.size.height / 2) / map.scale

  map.position.x = map.position.x + originalX - newX
  map.position.y = map.position.y + originalY - newY

  SpwDebug:UpdateItem("zoom", scale)
  SpwMap:MoveMap()
end

function SpwMap:HandleMouseDown()
  local effectiveScale = self.mapFrame:GetEffectiveScale()
  SpwMap.Map.effectiveScale = effectiveScale

  local x, y = GetCursorPosition()
  x = x / effectiveScale
  y = y / effectiveScale

  SpwMap.Map.scroll.x = x
  SpwMap.Map.scroll.y = y
  SpwMap.Map.isDragging = true
end

function SpwMap:Init()
  SpwDebug:CreateDebugWindow()
  SpwDebug:AddItem("zoom", SpwMap.Map.scale)
  SpwDebug:AddItem("MapX", SpwMap.Map.position.x)
  SpwDebug:AddItem("MapY", SpwMap.Map.position.y)
  SpwDebug:AddItem("MapWidth", SpwMap.Map.size.width)
  SpwDebug:AddItem("MapHeight", SpwMap.Map.size.height)
  local x, y = GetPlayerMapPosition("player")
  SpwDebug:AddItem("PlayerPos", string.format("%.2f, %.2f", x, y))

  self.frame = UI:CreateWindow("SpwMapMain", SpwMap.Map.size.width, SpwMap.Map.size.height, UIParent)
  self.frame:SetPoint("Center", 0, 0)
  self.frame:SetTitle("SpwMap")
  self.frame:SetScript("OnSizeChanged", function()
    SpwMap.Map.size.width = self.frame:GetWidth()
    SpwMap.Map.size.height = self.frame:GetHeight()
  end)

  self.mapFrame = UI:CreateNestedWindow(self.frame, "MapFrame", FRAME_WIDTH, FRAME_HEIGHT)
  self.mapFrame:SetAllPoints(self.frame)
  self.mapFrame:EnableMouse(true)
  self.mapFrame:EnableMouseWheel(true)

  self.mapFrame:SetScript("OnMouseWheel", function() SpwMap:handleZoom() end)
  self.mapFrame:SetScript("OnMouseDown", function() SpwMap:HandleMouseDown() end)
  self.mapFrame:SetScript("OnMouseUp", function() SpwMap.Map.isDragging = false end)
  self.mapFrame:SetScript("OnUpdate", function() SpwMap:HandleUpdate() end)

  SpwMap:InitContinents()
  SpwMap:MoveMap(SpwMap.Map.position.x, SpwMap.Map.position.y)
end

function SpwMap:onEvent()
  if event == "ADDON_LOADED" and arg1 == "spwmap-playground" then
    Utils.log("SP LOADED")
    self.frame:Show()
  end
end

---Handles the map movement
---@param xPos? number
---@param yPos? number
function SpwMap:MoveMap(xPos, yPos)
  if xPos and yPos then
    SpwMap.Map.position.x = xPos
    SpwMap.Map.position.y = yPos
  else
    SpwMap.Map.effectiveScale = SpwMap.mapFrame:GetEffectiveScale()

    local cursorX, cursorY = GetCursorPosition()

    cursorX = cursorX / SpwMap.Map.effectiveScale
    cursorY = cursorY / SpwMap.Map.effectiveScale

    local x = cursorX - SpwMap.Map.scroll.x
    local y = cursorY - SpwMap.Map.scroll.y

    SpwMap.Map.scroll.x = cursorX
    SpwMap.Map.scroll.y = cursorY

    local mx = x / SpwMap.Map.scale
    local my = y / SpwMap.Map.scale

    SpwMap.Map.position.x = SpwMap.Map.position.x - mx
    SpwMap.Map.position.y = SpwMap.Map.position.y + my

    SpwDebug:UpdateItem("MapX", SpwMap.Map.position.x)
    SpwDebug:UpdateItem("MapY", SpwMap.Map.position.y)
  end

  SpwMap:MoveContinents()
end

function SpwMap:MoveContinents()
  for continentIndex in ipairs(Utils.GetContinents()) do
    self:MoveZoneTiles(continentIndex, continentIndex * 1000, self.continentFrames[continentIndex])
  end
end

---Moves zone tiles
---@param continentIndex number
---@param zoneId number
---@param frames Frame[]
function SpwMap:MoveZoneTiles(continentIndex, zoneId, frames)
  local row, col = 0, 0
  local frameX, frameY
  local scale = self.Map.scale
  local clipW = self.Map.size.width
  local clipH = self.Map.size.height

  local zname, xPos, yPos, zoneWidth, zoneHeight = Utils.GetWorldZoneInfo(continentIndex, zoneId)

  local baseWidth = zoneWidth * SPWMAP_FRAME_WIDTH / SPWMAP_DETAIL_FRAME_WIDTH / SPWMAP_NUM_MAP_COLUMNS * scale
  local baseHeight = zoneHeight * SPWMAP_FRAME_HEIGHT / SPWMAP_DETAIL_FRAME_HEIGHT / SPWMAP_NUM_MAP_ROWS * scale

  local x = (xPos - self.Map.position.x) * scale + clipW / 2
  local y = (yPos - self.Map.position.y) * scale + clipH / 2

  for i = 1, SPWMAP_NUM_MAP_COLUMNS * SPWMAP_NUM_MAP_ROWS do
    local frame = frames[i]
    if frame then
      row = Utils.mod(i - 1, SPWMAP_NUM_MAP_COLUMNS)
      col = math.floor((i - 1) / SPWMAP_NUM_MAP_COLUMNS)

      frameX = row * baseWidth + x
      frameY = col * baseHeight + y

      if baseWidth <= 0 or baseHeight <= 0 then
        frame:Hide()
      else
        frame:SetPoint("TopLeft", frameX, -frameY)
        frame:SetWidth(baseWidth)
        frame:SetHeight(baseHeight)

        frame:Show()
      end
    end
  end
end

function SpwMap:InitContinents()
  Utils.log('SpwMap:InitContinents')

  local texturePath

  for continentIndex in ipairs(Utils.GetContinents()) do
    local continentBlocks = SPWMAP_CONTINENT_BLOCKS[continentIndex]
    self.continentFrames[continentIndex] = {}

    local mapInfo = SpwMap.Map.MapInfo[continentIndex]
    local mapFileName = mapInfo.FileName

    for blockIndex, block in ipairs(continentBlocks) do
      if block ~= 0 then
        texturePath = SPWMAP_WORLD_MAP_BASE_TEXTURE_PATH .. mapFileName .. "\\" .. mapFileName .. blockIndex
        local continentFrame = CreateFrame("Frame", nil, self.mapFrame)
        local t = continentFrame:CreateTexture(nil, "ARTWORK")
        t:SetAllPoints(continentFrame)
        t:SetTexture(texturePath)
        self.continentFrames[continentIndex][blockIndex] = continentFrame
      end
    end
  end
end

function SpwMap:HandleUpdate()
  if SpwMap.Map.isDragging then
    SpwMap:MoveMap()
  end
  SpwDebug:UpdateItem("MapWidth", SpwMap.Map.size.width)
  SpwDebug:UpdateItem("MapHeight", SpwMap.Map.size.height)
end

SpwMap:Init()
