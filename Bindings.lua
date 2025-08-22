BINDING_HEADER_GOGGLEMAPS_HEADER = "GoggleMaps"
BINDING_NAME_GOGGLEMAPS_TOGGLEMAP = "Toggle Map"
BINDING_NAME_GOGGLEMAPS_TOGGLE_BLIZZMAP = "Toggle Original Map"

local MAP_KEY = "M"
local ALT_MAP_KEY = "ALT-" .. MAP_KEY

local function MyAddon_SetBindings()
  -- Try to set up custom bindings
  local ok, err = pcall(function()
    -- Unbind Blizzard's map key
    SetBinding(MAP_KEY)
    -- Bind M to your addon
    SetBinding(MAP_KEY, "GOGGLEMAPS_TOGGLEMAP")
    -- Bind ALT-M to Blizzard’s map
    SetBinding(ALT_MAP_KEY, "GOGGLEMAPS_TOGGLE_BLIZZMAP")
    -- Save (2 = per character, 1 = account-wide)
    SaveBindings(2)
  end)

  -- If something went wrong, restore Blizzard's default
  if not ok then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[GoggleMaps] Error setting keybindings: " ..
      err .. " - Restoring Blizzard default.|r")
    SetBinding(MAP_KEY, "TOGGLEWORLDMAP")
    SaveBindings(2)
  end
end

-- Run when player logs in
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", MyAddon_SetBindings)
