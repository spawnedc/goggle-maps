setfenv(1, GoggleMaps)

local UI = GoggleMaps.UI.Window
local ADDON_NAME = GoggleMaps.name

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

function GoggleMaps:Start()
  self.frame = UI:CreateWindow(ADDON_NAME .. "Main", self.Map.size.width, self.Map.size.height, UIParent)
  self.frame:SetFrameLevel(self.frameLevels.mainFrame)
  self.frame:SetFrameStrata("HIGH")
  self.frame:RegisterEvent("ADDON_LOADED")

  self.frame:SetScript("OnEvent", function() GoggleMaps:OnEvent() end)
  self.frame:Hide()
end

function GoggleMaps:Init()
  GMapsDebug:CreateDebugWindow()

  local version = GetAddOnMetadata(ADDON_NAME, "Version")
  local title = GetAddOnMetadata(ADDON_NAME, "Title")

  self.frame:SetTitle(title .. " v" .. version)
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

  self.frame:Show()
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
  local playerPos = self.Player.position
  self.frame:SetTitle(string.format("%s %.1f, %.1f", GetRealZoneText(), playerPos.x, playerPos.y))
end

GoggleMaps:Start()
