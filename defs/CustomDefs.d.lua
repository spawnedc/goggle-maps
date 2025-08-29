---@type Font
GameFontNormalSmall = GameFontNormalSmall
---@type Font
GameFontGreenSmall = GameFontGreenSmall
---@type Font
GameFontRedSmall = GameFontRedSmall

---Returns basic information about the instance, if the player is in one.
---@return number|nil isInInstance `1` if player is inside an instance, `nil` otherwise
---@return "none"|"party"|"raid"|"pvp" instanceType `"none"` when outside an instance, `"party"` when in a 5-man instance, `"pvp"` when in a battleground, `"raid"` when in a raid instance
function IsInInstance() end
