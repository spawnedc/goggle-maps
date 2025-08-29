setfenv(1, GoggleMaps)

GoggleMaps.compat.atlas = {
  ---@type Frame
  frame = nil,
  initialised = false,
}

function GoggleMaps.compat.atlas:Init(parentFrame)
  self.frame = CreateFrame("Frame", "GoggleMapsCompatAtlasFrame", parentFrame)
  self.frame:SetAllPoints()
  self.frame:SetFrameLevel(GoggleMaps.frameLevels.city)
end

function GoggleMaps.compat.atlas:Start()
  Utils.print("atlas module loaded!")

  local originalHandleEvent = GoggleMaps.Map.handleEvent

  ---@diagnostic disable-next-line: duplicate-set-field
  function GoggleMaps.Map:handleEvent()
    if event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" then
      Utils.print('stolen from Map.handleEvent')
      local isInInstance, instanceType = IsInInstance()
      if not isInInstance then
        originalHandleEvent(GoggleMaps.Map)
        return
      end

      Utils.print("instanceType: %s", instanceType)
      local zoneID = ATLAS_DROPDOWNS[AtlasOptions.AtlasType][AtlasOptions.AtlasZone];
      local info = AtlasMaps[zoneID];
      if info then
        Utils.debug("Atlas info: %s", info.ZoneName[1])
      else
        Utils.debug("No Atlas info")
      end
    end
  end
end
