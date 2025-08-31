---@type Font
GameFontNormalSmall = GameFontNormalSmall
---@type Font
GameFontGreenSmall = GameFontGreenSmall
---@type Font
GameFontRedSmall = GameFontRedSmall

---@alias InstanceType
---| "none" # player is not in an instance
---| "party" # player in a 5-man instance
---| "raid" # player in a battleground
---| "pvp" # player in a raid instance

---Returns basic information about the instance, if the player is in one.
---@return number|nil isInInstance `1` if player is inside an instance, `nil` otherwise
---@return InstanceType instanceType
function IsInInstance() end
