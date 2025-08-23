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

  self.frame:SetScript("OnEvent", function() GoggleMaps:OnEvent() end)
  self.frame:Hide()
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
  self.frame:SetMinResize(300, 300)

  local contentFrame = self.frame.Content

  self.Map:Init(contentFrame)
  self.Overlay:Init(contentFrame)
  self.POI:Init(contentFrame)
  self.Minimap:Init(contentFrame)
  self.Map:InitZones()
  self.Player:Init(contentFrame)
  self.Hotspots:Init()

  self.frame:SetScript("OnUpdate", function() self:handleUpdate() end)
  self.frame:SetScript("OnSizeChanged", function() self:handleSizeChanged() end)

  self:handleSizeChanged()
  Utils.print("READY!")
end

function GoggleMaps:OnEvent()
  if event == "ADDON_LOADED" and arg1 == GoggleMaps.name then
    Utils.print("AddonLoaded")
    self:Init()
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
  self.Player:handleUpdate(self.Map.mapId == self.Map.realMapId)
  self:UpdateLocationText()
end

function GoggleMaps:UpdateLocationText()
  if not self.Map.realMapId then
    return
  end

  local area = self.Map.Area[self.Map.realMapId]
  local playerFaction = UnitFactionGroup("player")
  local playerFactionId = UNIT_FACTION_TO_FACTION_ID[playerFaction]
  local playerPos = self.Player.position
  ---@type Font
  local fontObj
  if area.faction == 0 then
    fontObj = "GameFontNormalSmall" -- "|cffff6060"
  elseif playerFactionId == area.faction then
    fontObj = "GameFontGreenSmall"  -- "|cff20ff20"
  else
    fontObj = "GameFontRedSmall"    -- "|cffffff00"
  end
  self.locationLabel:SetFontObject(fontObj)
  self.locationLabel:SetText(GetRealZoneText())
  self.positionLabel:SetText(string.format("%.1f, %.1f", playerPos.x, playerPos.y))
end

GoggleMaps:Start()
