BINDING_HEADER_GOGGLEMAPS_HEADER = "GoggleMaps"
BINDING_NAME_GOGGLEMAPS_TOGGLEMAP = "Toggle Map"
BINDING_NAME_GOGGLEMAPS_TOGGLE_BLIZZMAP = "Toggle Original Map"

local function MyAddon_SetBindings()
  -- Try to set up custom bindings
  local ok, err = pcall(function()
    -- Already bound (from a previous login, or the user rebound it manually) - leave it alone
    if GetBindingKey("GOGGLEMAPS_TOGGLEMAP") then
      return
    end

    -- Take over whatever key the user actually has bound to the default map
    local mapKey = GetBindingKey("TOGGLEWORLDMAP") or "M"
    local altMapKey = "ALT-" .. mapKey

    -- Unbind Blizzard's map key
    SetBinding(mapKey)
    -- Bind it to your addon
    SetBinding(mapKey, "GOGGLEMAPS_TOGGLEMAP")
    -- Bind ALT-<key> to Blizzard’s map
    SetBinding(altMapKey, "GOGGLEMAPS_TOGGLE_BLIZZMAP")
    -- Save (2 = per character, 1 = account-wide)
    SaveBindings(2)
  end)

  -- If something went wrong, restore Blizzard's default
  if not ok then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[GoggleMaps] Error setting keybindings: " ..
      err .. " - Restoring Blizzard default.|r")
    SetBinding("M", "TOGGLEWORLDMAP")
    SaveBindings(2)
  end
end

-- Run when player logs in
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", MyAddon_SetBindings)
