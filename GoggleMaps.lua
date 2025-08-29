setfenv(1, GoggleMaps)

local UI = GoggleMaps.UI.Window
local ADDON_NAME = GoggleMaps.name

---@type Frame
GoggleMaps.debugFrame = nil
---@type Frame
GoggleMaps.frame = nil
GoggleMaps.frameLevels = {
  mainFrame = 1,
  continent = 10,
  overlay = 20,
  poi = 25,
  minimap = 30,
  city = 40,
  pfQuest = 45,
  player = 100
}
---@type FontString
GoggleMaps.locationLabel = nil
---@type FontString
GoggleMaps.positionLabel = nil
GoggleMaps.wasDragging = false

function GoggleMaps:InitDB(force)
  Utils.print("InitDB")
  local DB = _G.GoggleMapsDB
  if not DB or force then
    DB = {
      DEBUG_MODE = false,
      isMini = false,
      position = { -- center
        x = 0,
        y = 0,
      },
      size = {
        width = 1024,
        height = 768
      },
      miniPosition = {
        x = 0,
        y = 0
      },
      miniSize = {
        width = 200,
        height = 200
      }
    }
    _G.GoggleMapsDB = DB
  end

  self.DEBUG_MODE = DB.DEBUG_MODE
  self.isMini = DB.isMini
  self:RestoreSizeAndPosition()

  if force then
    self.frame:ClearAllPoints()
    self.frame:SetPoint("Center", UIParent, "Center", DB.position.x, DB.position.y)
    self.frame:SetWidth(DB.size.width)
    self.frame:SetHeight(DB.size.height)
  end
end

function GoggleMaps:ResetDB()
  _G.GoggleMapsDB = nil

  self:InitDB(true)
  self.Map:InitDB(true)
  self.Overlay:InitDB()
end

function GoggleMaps:Start()
  self.frame = UI:CreateWindow(ADDON_NAME .. "Main", 1024, 768, UIParent)
  self.frame:SetFrameLevel(self.frameLevels.mainFrame)
  self.frame:SetFrameStrata("HIGH")
  self.frame:RegisterEvent("PLAYER_LOGIN")
  self.locationLabel = self.frame.TitleBar:CreateFontString("location", "OVERLAY", "GameFontNormalSmall")
  self.positionLabel = self.frame.TitleBar:CreateFontString("position", "OVERLAY", "GameFontNormalSmall")
  self.locationLabel:SetPoint("Left", self.frame.TitleBar, "Left", 4, 0)
  self.positionLabel:SetPoint("Left", self.locationLabel, "Right", 4, 0)

  self:InitCurrentMapInfo()

  self.frame:SetScript("OnEvent", function() GoggleMaps:OnEvent() end)
  self.frame:Hide()
end

function GoggleMaps:InitCurrentMapInfo()
  local frame = CreateFrame("Frame", nil, self.frame.Clip)
  frame:SetPoint("TopRight", 0, 1)
  frame:SetWidth(300)
  frame:SetHeight(32)
  local titleTex = frame:CreateTexture(nil, "BACKGROUND")
  titleTex:SetAllPoints(frame)
  titleTex:SetTexture(0.1, 0.1, 0.1, 0.9)

  local continentLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  local locationLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  local positionLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  continentLabel:SetPoint("TopLeft", frame, "TopLeft", 4, -4)
  locationLabel:SetPoint("TopLeft", continentLabel, "TopRight", 0, 0)
  positionLabel:SetPoint("TopRight", locationLabel, "BottomRight", 0, -4)

  frame.continentLabel = continentLabel
  frame.locationLabel = locationLabel
  frame.positionLabel = positionLabel

  frame:Hide()

  self.currentMapInfoFrame = frame
end

function GoggleMaps:Toggle()
  if not self.frame:IsVisible() then
    -- just show the frame without touching isMini
    self.frame:Show()
    if self.DEBUG_MODE then
      self.debugFrame:Show()
    end
  else
    -- toggle between mini and maxi
    self.isMini = not self.isMini
    GoggleMapsDB.isMini = self.isMini

    self:RestoreSizeAndPosition()
  end
end

function GoggleMaps:RestoreSizeAndPosition()
  local x = self.isMini and GoggleMapsDB.miniPosition.x or GoggleMapsDB.position.x
  local y = self.isMini and GoggleMapsDB.miniPosition.y or GoggleMapsDB.position.y

  local w = self.isMini and GoggleMapsDB.miniSize.width or GoggleMapsDB.size.width
  local h = self.isMini and GoggleMapsDB.miniSize.height or GoggleMapsDB.size.height

  Utils.debug("Restoring size: isMini=%s %.2f, %.2f", tostring(self.isMini), w, h)
  self.frame:SetWidth(w)
  self.frame:SetHeight(h)

  Utils.debug("Restoring position: isMini=%s %.2f, %.2f", tostring(self.isMini), x, y)
  self.frame:ClearAllPoints()
  self.frame:SetPoint("Center", UIParent, "Center", x, y)
end

function GoggleMaps:UpdateDBSize()
  local w = self.frame:GetWidth()
  local h = self.frame:GetHeight()
  Utils.debug("UpdateDBSize isMini=%s %.2f, %.2f", tostring(self.isMini), w, h)
  if self.isMini then
    GoggleMapsDB.miniSize.width = w
    GoggleMapsDB.miniSize.height = h
  else
    GoggleMapsDB.size.width = w
    GoggleMapsDB.size.height = h
  end
end

function GoggleMaps:UpdateDBPos()
  local cx, cy = self.frame:GetCenter()
  local px, py = self.frame:GetParent():GetCenter()
  local x = cx - px
  local y = cy - py
  Utils.debug("UpdateDBPos isMini=%s %.2f, %.2f", tostring(self.isMini), x, y)
  if self.isMini then
    GoggleMapsDB.miniPosition.x = x
    GoggleMapsDB.miniPosition.y = y
  else
    GoggleMapsDB.position.x = x
    GoggleMapsDB.position.y = y
  end
end

function GoggleMaps:ToggleDebug()
  self.DEBUG_MODE = not self.DEBUG_MODE
  GoggleMapsDB.DEBUG_MODE = self.DEBUG_MODE

  if self.DEBUG_MODE then
    Utils.debug("Debug mode ON")
    self.debugFrame:Show()
  else
    -- let it print one more debug messasge before going offline...
    self.DEBUG_MODE = true
    Utils.debug("Debug mode OFF")
    self.DEBUG_MODE = false
    self.debugFrame:Hide()
  end
end

function GoggleMaps:Init()
  self:InitDB()
  self.debugFrame = GMapsDebug:CreateDebugWindow()

  self.frame:SetMinResize(200, 200)
  self.frame:SetClampedToScreen(true)

  local contentFrame = self.frame.Content

  self.Map:Init(contentFrame)
  self.Overlay:Init(contentFrame)
  self.POI:Init(contentFrame)
  self.Minimap:Init(contentFrame)
  self.Map:InitZones()

  GoggleMaps.compat.pfQuest:Init(self.frame.Content)
  GoggleMaps.compat.atlas:Init(self.frame.Content)

  self.Player:Init(contentFrame)
  self.Hotspots:Init()

  self.frame:SetScript("OnUpdate", function() self:handleUpdate() end)
  self.frame:SetScript("OnSizeChanged", function() self:handleSizeChanged() end)

  self:handleSizeChanged()
  self.frame:Show()
  Utils.print("READY!")
end

function GoggleMaps:OnEvent()
  if event == "PLAYER_LOGIN" then
    Utils.debug("AddonLoaded")
    self:Init()

    if pfMap then
      GoggleMaps.compat.pfQuest:Start()
    end

    if AtlasMap then
      GoggleMaps.compat.atlas:Start()
    end
  end
end

function GoggleMaps:handleSizeChanged()
  self:UpdateDBSize()
  local width, height = self.frame:SetContentSize()
  self.Map.size.width = width
  self.Map.size.height = height
  self.Map:MoveMap(self.Map.position.x, self.Map.position.y)
end

function GoggleMaps:handleUpdate()
  if self.wasDragging and not self.frame.isDragging then
    self.wasDragging = false
    self:UpdateDBPos()
  elseif not self.wasDragging and self.frame.isDragging then
    self.wasDragging = true
  end
  self.Map:handleUpdate()
  self.Overlay:handleUpdate()
  self.POI:handleUpdate()
  self.Minimap:handleUpdate()
  if self.compat.pfQuest.initialised then
    self.compat.pfQuest:handleUpdate()
  end
  self.Player:handleUpdate(self.Map.mapId == self.Map.realMapId)
  self:UpdateLocationText()
  self:UpdateCurrentMapInfo()
end

function GoggleMaps:UpdateLocationText()
  if not self.Map.realMapId then
    return
  end

  local fontObj = Utils.getlocationFontObject(self.Map.realMapId)
  self.locationLabel:SetFontObject(fontObj)
  self.locationLabel:SetText(GetRealZoneText())
  local playerPos = self.Player.position
  self.positionLabel:SetText(string.format("%.1f, %.1f", playerPos.x, playerPos.y))
end

function GoggleMaps:UpdateCurrentMapInfo()
  if self.Map.mapId == self.Map.realMapId then
    self.currentMapInfoFrame:Hide()
  else
    local mapId = self.Map.mapId

    if not mapId then
      return
    end
    local frame = self.currentMapInfoFrame
    --- @type FontString
    local continentLabel = frame.continentLabel
    --- @type FontString
    local locationLabel = frame.locationLabel
    --- @type FontString
    local positionLabel = frame.positionLabel

    local continentInfo = self.Map.Area[Utils.getContinentId(mapId) * 1000]
    local zoneInfo = self.Map.Area[mapId]

    continentLabel:SetText(continentInfo.name .. ", ")
    continentLabel:SetWidth(continentLabel:GetStringWidth())

    local locationFont = Utils.getlocationFontObject(mapId)
    locationLabel:SetText(zoneInfo.name)
    locationLabel:SetFontObject(locationFont)
    locationLabel:SetWidth(locationLabel:GetStringWidth())

    frame:Show()

    -- local dist = ((wx - map.PlyrX) ^ 2 + (wy - map.PlyrY) ^ 2) ^ .5 * 4.575

    local winx, winy = Utils.getMouseOverPos(self.frame)
    if winx and winy then
      local worldX, worldY = Utils.FramePosToWorldPos(winx, winy)
      local zoneX, zoneY = Utils.GetZonePosFromWorldPos(mapId, worldX, worldY)
      positionLabel:SetText(string.format("|cff80b080%.1f, %.1f", zoneX, zoneY))
      if zoneX < 0 or zoneX > 100 or zoneY < 0 or zoneY > 100 then
        frame:Hide()
      end
    end

    local totalWidth = continentLabel:GetWidth() + locationLabel:GetWidth() + 8
    frame:SetWidth(totalWidth)
  end
end

GoggleMaps:Start()
