setfenv(1, GoggleMaps)

GoggleMaps.compat.atlas = {
  ---@type Frame
  frame = nil,
  ---@type Texture
  mapTexture = nil,
  initialised = false,
}

function GoggleMaps.compat.atlas:Init(parentFrame)
  self.frame = CreateFrame("Frame", "GoggleMapsCompatAtlasFrame", parentFrame)
  self.frame:SetAllPoints()
  self.frame:SetFrameLevel(GoggleMaps.frameLevels.city)
  self.mapTexture = self.frame:CreateTexture(nil, "OVERLAY")
  self.mapTexture:SetAllPoints()
  self.frame:Hide()
end

function GoggleMaps.compat.atlas:Start()
  Utils.print("Atlas module loaded!")

  local originalHandleEvent = GoggleMaps.Map.handleEvent

  ---@diagnostic disable-next-line: duplicate-set-field
  function GoggleMaps.Map:handleEvent()
    Utils.print(event)
    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
      GoggleMaps.compat.atlas:handleEvent(originalHandleEvent)
    end
  end
end

function GoggleMaps.compat.atlas:handleEvent(originalHandleEvent)
  local isInInstance, instanceType = IsInInstance()
  if not isInInstance then
    Utils.print("Not in instance")
    GoggleMaps.Map:EnableInteraction()
    GoggleMaps.Player.frame:Show()
    GoggleMaps.POI.frame:Show()
    GoggleMaps.compat.pfQuest.frame:Show()
    self.frame:Hide()
    originalHandleEvent(GoggleMaps.Map)
    return
  end

  GoggleMaps.Map:DisableInteraction()
  GoggleMaps.Player.frame:Hide()
  GoggleMaps.POI.frame:Hide()
  GoggleMaps.compat.pfQuest.frame:Hide()
  self.frame:Show()

  local atlasTexture = AtlasMap:GetTexture()

  if atlasTexture then
    self.mapTexture:SetTexture(atlasTexture)
    Utils.print("Atlas info: %s", atlasTexture)
  else
    Utils.print("No Atlas info")
  end
end
