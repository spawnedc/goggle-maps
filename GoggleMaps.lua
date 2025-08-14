setfenv(1, GoggleMaps)

local UI = GoggleMaps.UI.Window

---@type Frame
GoggleMaps.frame = nil

function GoggleMaps:Start()
  GMapsDebug:CreateDebugWindow()

  local ADDON_NAME = GoggleMaps.name
  local version = GetAddOnMetadata(ADDON_NAME, "Version")
  local title = GetAddOnMetadata(ADDON_NAME, "Title")

  self.frame = UI:CreateWindow(ADDON_NAME .. "Main", self.Map.size.width, self.Map.size.height, UIParent)
  self.frame:SetPoint("Center", UIParent, "Center", 0, 0)
  self.frame:SetTitle(title .. " v" .. version)
  self.frame:RegisterEvent("ADDON_LOADED")
  self.frame:SetScript("OnEvent", function() GoggleMaps:OnEvent() end)
  self.frame:Hide()
end

function GoggleMaps:Init()
  self.Map:Init(self.frame)
  self.Overlay:Init()

  self.frame:SetScript("OnUpdate", function() self:handleUpdate() end)
  self.frame:SetScript("OnSizeChanged", function()
    self.Map.size.width = self.frame:GetWidth()
    self.Map.size.height = self.frame:GetHeight()
    self.Map:MoveMap(self.Map.position.x, self.Map.position.y)
  end)

  self.frame:Show()
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
end

GoggleMaps:Start()
