setfenv(1, GoggleMaps)

GoggleMaps.compat.atlas = {
  ---@type Frame
  frame = nil,
  ---@type Texture
  mapTexture = nil,
  initialised = false,
}

local ATLAS_TEXTURE_RATIO = 1 -- 512x512

function GoggleMaps.compat.atlas:Init(parentFrame)
  self.frame = CreateFrame("Frame", "GoggleMapsCompatAtlasFrame", parentFrame)
  self.frame:SetAllPoints()
  self.frame:SetFrameLevel(GoggleMaps.frameLevels.city)
  self.frame:SetScript("OnSizeChanged", function() self:handleSizeChanged() end)

  local bg = self.frame:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(self.frame)
  bg:SetTexture(0, 0, 0, 1) -- black, fully opaque

  self.mapTexture = self.frame:CreateTexture(nil, "OVERLAY")
  self.mapTexture:SetAllPoints()
  self.frame:Hide()
end

function GoggleMaps.compat.atlas:Start()
  Utils.print("Atlas module loaded!")

  local originalHandleEvent = GoggleMaps.Map.handleEvent

  ---@diagnostic disable-next-line: duplicate-set-field
  function GoggleMaps.Map:handleEvent()
    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
      GoggleMaps.compat.atlas:handleEvent(originalHandleEvent)
    end
  end
end

function GoggleMaps.compat.atlas:handleSizeChanged()
  if self.frame:IsShown() then
    local frameWidth, frameHeight = self.frame:GetWidth(), self.frame:GetHeight()
    local frameRatio = frameWidth / frameHeight

    if ATLAS_TEXTURE_RATIO > frameRatio then
      self.mapTexture:SetWidth(frameWidth)
      self.mapTexture:SetHeight(frameWidth / ATLAS_TEXTURE_RATIO)
    else
      self.mapTexture:SetHeight(frameHeight)
      self.mapTexture:SetWidth(frameHeight * ATLAS_TEXTURE_RATIO)
    end

    self.mapTexture:ClearAllPoints()
    self.mapTexture:SetPoint("Center", self.frame, "Center")
  end
end

function GoggleMaps.compat.atlas:handleEvent(originalHandleEvent)
  local isInInstance, instanceType = IsInInstance()
  if not isInInstance then
    GoggleMaps.Map:EnableInteraction()
    GoggleMaps.Player.frame:Show()
    GoggleMaps.POI.frame:Show()
    GoggleMaps.compat.pfQuest.frame:Show()
    self.frame:Hide()
    originalHandleEvent(GoggleMaps.Map)
    return
  end

  -- Force auto detection
  Atlas_AutoSelect()

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
