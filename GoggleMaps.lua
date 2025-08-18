setfenv(1, GoggleMaps)

local UI = GoggleMaps.UI.Window
local ADDON_NAME = GoggleMaps.name

---@type Frame
GoggleMaps.frame = nil
GoggleMaps.frameLevels = {
  mainFrame = 1,
  continent = 10,
  overlay = 20,
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

  local parentFrame = self.frame.Content

  self.Map:Init(parentFrame)
  self.Overlay:Init(parentFrame)
  self.Minimap:Init(parentFrame)
  self.Map:InitZones()
  self.Player:Init(parentFrame)
  self.Hotspots:Init()

  self.frame:SetScript("OnUpdate", function() self:handleUpdate() end)
  self.frame:SetScript("OnSizeChanged", function()
    self.Map.size.width = self.frame:GetWidth()
    self.Map.size.height = self.frame:GetHeight()
    self.Map:MoveMap(self.Map.position.x, self.Map.position.y)
  end)

  self.frame:Show()
  self.Map:MoveMap(self.Map.position.x, self.Map.position.y)
  Utils.print("READY!")
end

function GoggleMaps:OnEvent()
  if event == "ADDON_LOADED" and arg1 == GoggleMaps.name then
    Utils.print("AddonLoaded")
    self:Init()
  end
end

function GoggleMaps:handleUpdate()
  self.Map:handleUpdate()
  self.Overlay:handleUpdate()
  self.Minimap:handleUpdate()
  self.Player:handleUpdate(self.Map.mapId == self.Map.realMapId)
end

GoggleMaps:Start()
