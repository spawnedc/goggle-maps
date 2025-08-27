setfenv(1, GoggleMaps)

local UI = GoggleMaps.UI.Window
local ADDON_NAME = GoggleMaps.name

local UNIT_FACTION_TO_FACTION_ID = {
  Horde = 4,
  Alliance = 2,
}

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
  self.frame:RegisterEvent("ADDON_LOADED")
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
  frame:SetPoint("TopLeft", 0, 0)
  frame:SetWidth(300)
  frame:SetHeight(50)
  local titleTex = frame:CreateTexture(nil, "BACKGROUND")
  titleTex:SetAllPoints(frame)
  titleTex:SetTexture(0.1, 0.1, 0.1, 0.9)


  local locationLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  local positionLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  locationLabel:SetPoint("Left", frame, "Left", 4, 0)
  positionLabel:SetPoint("TopLeft", locationLabel, "BottomLeft", 4, 0)

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
  if event == "ADDON_LOADED" then
    if arg1 == GoggleMaps.name then
      Utils.debug("AddonLoaded")
      self:Init()
    end

    if arg1 == "pfQuest" then
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
    self.currentMapInfoFrame:Show()
  end
end

GoggleMaps:Start()
