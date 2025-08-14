setfenv(1, GoggleMaps)

local UI = GoggleMaps.UI.Window

---@type Frame
GoggleMaps.frame = nil

function GoggleMaps:Init()
  GMapsDebug:CreateDebugWindow()

  local ADDON_NAME = GoggleMaps.name
  local version = GetAddOnMetadata(ADDON_NAME, "Version")
  local title = GetAddOnMetadata(ADDON_NAME, "Title")

  self.frame = UI:CreateWindow(ADDON_NAME .. "Main", GoggleMaps.Map.size.width, GoggleMaps.Map.size.height, UIParent)
  self.frame:SetPoint("Center", UIParent, "Center", 0, 0)
  self.frame:SetTitle(title .. " v" .. version)
  self.frame:SetScript("OnUpdate", function() self:handleUpdate() end)
  self.frame:SetScript("OnSizeChanged", function()
    GoggleMaps.Map.size.width = self.frame:GetWidth()
    GoggleMaps.Map.size.height = self.frame:GetHeight()
  end)

  GoggleMaps.Map:Init(self.frame)
end

function GoggleMaps:onEvent()
  if event == "ADDON_LOADED" and arg1 == GoggleMaps.name then
    Utils.print("Loaded")
    self.frame:Show()
  end
end

function GoggleMaps:handleUpdate()
  GoggleMaps.Map:handleUpdate()
end

GoggleMaps:Init()
