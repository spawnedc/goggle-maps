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

-- While minimizeOnEscape is on, our frame is pulled out of UISpecialFrames (see
-- UpdateEscapeRegistration below) so the built-in Escape handling skips straight over it -
-- our own hook is the only thing that reacts to Escape for it in that case. While the
-- setting is off, the frame stays registered and Escape closes it via the normal
-- UISpecialFrames/HideUIPanel mechanism, regardless of mini/maxi state.
local function UpdateEscapeRegistration()
  local name = GoggleMaps.frame and GoggleMaps.frame:GetName()
  if not name then
    return
  end

  for i = 1, table.getn(UISpecialFrames) do
    if UISpecialFrames[i] == name then
      table.remove(UISpecialFrames, i)
      break
    end
  end

  if not GoggleMaps.Options.minimizeOnEscape then
    table.insert(UISpecialFrames, name)
  end
end

-- The ESCAPE keybinding calls the real global ToggleGameMenu() directly (see Bindings.xml).
-- Patch the real global (not a sandboxed copy) so the keybinding dispatcher sees the override.
local Blizzard_ToggleGameMenu = _G.ToggleGameMenu
_G.ToggleGameMenu = function()
  if GoggleMaps.frame and GoggleMaps.frame:IsShown() and GoggleMaps.Options.minimizeOnEscape and not GoggleMaps.isMini then
    GoggleMaps.isMini = true
    GoggleMapsDB.isMini = true
    GoggleMaps:RestoreSizeAndPosition()
    return
  end
  -- Either the setting is off (frame is in UISpecialFrames, closes as usual), or the
  -- setting is on and the map is already minimized (frame is untracked, so this just
  -- falls through to whatever Escape would otherwise do, e.g. the real game menu).
  Blizzard_ToggleGameMenu()
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
    UpdateEscapeRegistration()
  end)

  local label = getglobal(checkbox:GetName() .. "Text")
  label:SetText("Minimize map instead of closing it when pressing Escape")
  label:SetWidth(220)
  label:SetJustifyH("LEFT")

  win:Hide()
  self.frame = win

  UpdateEscapeRegistration()
end

function GoggleMaps.Options:Toggle()
  if self.frame:IsShown() then
    self.frame:Hide()
  else
    self.frame:Show()
  end
end
