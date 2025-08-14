setfenv(1, SpwMap)

local UI = VanillaUI

---@type Frame
SpwMap.frame = nil

function SpwMap:Init()
  SpwDebug:CreateDebugWindow()

  self.frame = UI:CreateWindow("SpwMapMain", SpwMap.Map.size.width, SpwMap.Map.size.height, UIParent)
  self.frame:SetPoint("Center", UIParent, "Center", 0, 0)
  self.frame:SetTitle("SpwMap")
  self.frame:SetScript("OnUpdate", function() self:handleUpdate() end)
  self.frame:SetScript("OnSizeChanged", function()
    SpwMap.Map.size.width = self.frame:GetWidth()
    SpwMap.Map.size.height = self.frame:GetHeight()
  end)

  SpwMap.Map:Init(self.frame)
end

function SpwMap:onEvent()
  if event == "ADDON_LOADED" and arg1 == "spwmap-playground" then
    Utils.log("SP LOADED")
    self.frame:Show()
  end
end

function SpwMap:handleUpdate()
  SpwMap.Map:handleUpdate()
end

SpwMap:Init()
