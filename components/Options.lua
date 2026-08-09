setfenv(1, GoggleMaps)

local UI = GoggleMaps.UI.Window

GoggleMaps.Options = {
  ---@type Frame
  frame = nil,
  minimizeOnEscape = false
}

function GoggleMaps.Options:InitDB()
  if GoggleMapsDB.Options == nil then
    GoggleMapsDB.Options = {
      minimizeOnEscape = false
    }
  end
  self.minimizeOnEscape = GoggleMapsDB.Options.minimizeOnEscape
end

-- Escape normally hides frames listed in UISpecialFrames via the real global HideUIPanel.
-- Patch the real global (not a sandboxed copy) so FrameXML's ToggleGameMenu sees the override.
local Blizzard_HideUIPanel = _G.HideUIPanel
_G.HideUIPanel = function(frame)
  if frame == GoggleMaps.frame and GoggleMaps.Options.minimizeOnEscape and not GoggleMaps.isMini then
    GoggleMaps.isMini = true
    GoggleMapsDB.isMini = true
    GoggleMaps:RestoreSizeAndPosition()
    return
  end
  Blizzard_HideUIPanel(frame)
end

function GoggleMaps.Options:Init()
  self:InitDB()

  local win = UI:CreateWindow("GoggleMapsOptions", 280, 100, UIParent)
  win:SetTitle("GoggleMaps Options")
  win:SetPoint("Center", 0, 0)
  win:SetFrameStrata("DIALOG")

  local checkbox = CreateFrame("CheckButton", "GoggleMapsOptionsEscCheckbox", win.Content, "UICheckButtonTemplate")
  checkbox:SetPoint("TopLeft", win.Content, "TopLeft", 8, -8)
  checkbox:SetChecked(self.minimizeOnEscape)
  checkbox:SetScript("OnClick", function()
    GoggleMaps.Options.minimizeOnEscape = checkbox:GetChecked() and true or false
    GoggleMapsDB.Options.minimizeOnEscape = GoggleMaps.Options.minimizeOnEscape
  end)

  local label = getglobal(checkbox:GetName() .. "Text")
  label:SetText("Minimize map instead of closing it when pressing Escape")
  label:SetWidth(220)
  label:SetJustifyH("LEFT")

  win:Hide()
  self.frame = win
end

function GoggleMaps.Options:Toggle()
  if self.frame:IsShown() then
    self.frame:Hide()
  else
    self.frame:Show()
  end
end
