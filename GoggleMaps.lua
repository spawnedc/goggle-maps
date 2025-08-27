setfenv(1, GoggleMaps)

local UI = GoggleMaps.UI.Window
local ADDON_NAME = GoggleMaps.name

GoggleMaps.DEBUG_MODE = false
---@type Frame
GoggleMaps.debugFrame = nil
---@type Frame
GoggleMaps.frame = nil
GoggleMaps.frameLevels = {
  mainFrame = 1,
  continent = 10,
  overlay = 20,
  poi = 25,
  minimap = 30,
  city = 40,
  pfQuest = 45,
  player = 100
}
---@type FontString
GoggleMaps.locationLabel = nil
---@type FontString
GoggleMaps.positionLabel = nil

function GoggleMaps:Start()
  self.frame = UI:CreateWindow(ADDON_NAME .. "Main", self.Map.size.width, self.Map.size.height, UIParent)
  self.frame:SetFrameLevel(self.frameLevels.mainFrame)
  self.frame:SetFrameStrata("HIGH")
  self.frame:RegisterEvent("PLAYER_LOGIN")
  self.locationLabel = self.frame.TitleBar:CreateFontString("location", "OVERLAY", "GameFontNormalSmall")
  self.positionLabel = self.frame.TitleBar:CreateFontString("position", "OVERLAY", "GameFontNormalSmall")
  self.locationLabel:SetPoint("Left", self.frame.TitleBar, "Left", 4, 0)
  self.positionLabel:SetPoint("Left", self.locationLabel, "Right", 4, 0)

  self:InitCurrentMapInfo()

  self.frame:SetScript("OnEvent", function() GoggleMaps:OnEvent() end)
  self.frame:Hide()

  table.insert(UISpecialFrames, ADDON_NAME .. "Main")
end

function GoggleMaps:InitCurrentMapInfo()
  local frame = CreateFrame("Frame", nil, self.frame.Clip)
  frame:SetPoint("TopRight", 0, 1)
  frame:SetWidth(300)
  frame:SetHeight(32)
  local titleTex = frame:CreateTexture(nil, "BACKGROUND")
  titleTex:SetAllPoints(frame)
  titleTex:SetTexture(0.1, 0.1, 0.1, 0.9)

  local continentLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  local locationLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  local positionLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  continentLabel:SetPoint("TopLeft", frame, "TopLeft", 4, -4)
  locationLabel:SetPoint("TopLeft", continentLabel, "TopRight", 0, 0)
  positionLabel:SetPoint("TopRight", locationLabel, "BottomRight", 0, -4)

  frame.continentLabel = continentLabel
  frame.locationLabel = locationLabel
  frame.positionLabel = positionLabel

  frame:Hide()

  self.currentMapInfoFrame = frame
end

function GoggleMaps:Toggle()
  if self.frame:IsVisible() then
    self.frame:Hide()
    self.debugFrame:Hide()
  else
    self.frame:Show()
    if self.DEBUG_MODE then
      self.debugFrame:Show()
    end
  end
end

function GoggleMaps:ToggleDebug()
  self.DEBUG_MODE = not self.DEBUG_MODE

  if self.DEBUG_MODE then
    self.debugFrame:Show()
  else
    self.debugFrame:Hide()
  end
end

function GoggleMaps:Init()
  self.debugFrame = GMapsDebug:CreateDebugWindow()
  if not self.DEBUG_MODE then
    self.debugFrame:Hide()
  end
  self.debugFrame:Hide()
  self.frame:SetPoint("Center", UIParent, "Center", 0, 0)
  self.frame:SetMinResize(200, 200)

  local contentFrame = self.frame.Content

  self.Map:Init(contentFrame)
  self.Overlay:Init(contentFrame)
  self.POI:Init(contentFrame)
  self.Minimap:Init(contentFrame)
  self.Map:InitZones()

  GoggleMaps.compat.pfQuest:Init(self.frame.Content)

  self.Player:Init(contentFrame)
  self.Hotspots:Init()

  self.frame:SetScript("OnUpdate", function() self:handleUpdate() end)
  self.frame:SetScript("OnSizeChanged", function() self:handleSizeChanged() end)

  self:handleSizeChanged()
  Utils.print("READY!")
end

function GoggleMaps:OnEvent()
  if event == "PLAYER_LOGIN" then
    Utils.debug("AddonLoaded")
    self:Init()

    if pfMap then
      GoggleMaps.compat.pfQuest:Start()
    end
  end
end

function GoggleMaps:handleSizeChanged()
  local width, height = self.frame:SetContentSize()
  self.Map.size.width = width
  self.Map.size.height = height
  self.Map:MoveMap(self.Map.position.x, self.Map.position.y)
end

function GoggleMaps:handleUpdate()
  self.Map:handleUpdate()
  self.Overlay:handleUpdate()
  self.POI:handleUpdate()
  self.Minimap:handleUpdate()
  if self.compat.pfQuest.initialised then
    self.compat.pfQuest:handleUpdate()
  end
  self.Player:handleUpdate(self.Map.mapId == self.Map.realMapId)
  self:UpdateLocationText()
  self:UpdateCurrentMapInfo()
end

function GoggleMaps:UpdateLocationText()
  if not self.Map.realMapId then
    return
  end

  local fontObj = Utils.getlocationFontObject(self.Map.realMapId)
  self.locationLabel:SetFontObject(fontObj)
  self.locationLabel:SetText(GetRealZoneText())
  local playerPos = self.Player.position
  self.positionLabel:SetText(string.format("%.1f, %.1f", playerPos.x, playerPos.y))
end

function GoggleMaps:UpdateCurrentMapInfo()
  if self.Map.mapId == self.Map.realMapId then
    self.currentMapInfoFrame:Hide()
  else
    local mapId = self.Map.mapId
    local frame = self.currentMapInfoFrame
    --- @type FontString
    local continentLabel = frame.continentLabel
    --- @type FontString
    local locationLabel = frame.locationLabel
    --- @type FontString
    local positionLabel = frame.positionLabel

    local continentInfo = self.Map.Area[Utils.getContinentId(mapId) * 1000]
    local zoneInfo = self.Map.Area[mapId]

    continentLabel:SetText(continentInfo.name .. ", ")
    continentLabel:SetWidth(continentLabel:GetStringWidth())

    local locationFont = Utils.getlocationFontObject(mapId)
    locationLabel:SetText(zoneInfo.name)
    locationLabel:SetFontObject(locationFont)
    locationLabel:SetWidth(locationLabel:GetStringWidth())

    frame:Show()

    -- local dist = ((wx - map.PlyrX) ^ 2 + (wy - map.PlyrY) ^ 2) ^ .5 * 4.575

    local winx, winy = Utils.getMouseOverPos(self.frame)
    if winx and winy then
      local worldX, worldY = Utils.FramePosToWorldPos(winx, winy)
      local zoneX, zoneY = Utils.GetZonePosFromWorldPos(mapId, worldX, worldY)
      positionLabel:SetText(string.format("|cff80b080%.1f, %.1f", zoneX, zoneY))
      if zoneX < 0 or zoneX > 100 or zoneY < 0 or zoneY > 100 then
        frame:Hide()
      end
    end

    local totalWidth = continentLabel:GetWidth() + locationLabel:GetWidth() + 8
    frame:SetWidth(totalWidth)
  end
end

GoggleMaps:Start()
