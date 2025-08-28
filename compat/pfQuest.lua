setfenv(1, GoggleMaps)

GoggleMaps.compat.pfQuest = {
  ---@type Frame
  frame = nil,
  initialised = false,
  ---@type table<Frame>
  pins = {}

}

function GoggleMaps.compat.pfQuest:Init(parentFrame)
  self.frame = CreateFrame("Frame", "GoggleMapsCompatpfQuestFrame", parentFrame)
  self.frame:SetAllPoints()
  self.frame:SetFrameLevel(GoggleMaps.frameLevels.pfQuest)
end

function GoggleMaps.compat.pfQuest:Start()
  Utils.print("pfQuest module loaded!")
  local oldUpdateMap = pfMap.UpdateNodes

  function pfMap:UpdateNodes()
    oldUpdateMap(pfMap)
    GoggleMaps.compat.pfQuest:UpdateNodes(pfMap.pins)
  end
end

function GoggleMaps.compat.pfQuest:UpdateNodes(newPins)
  ---@type Frame
  local pin
  local point, relativeTo, relativePoint, pinX, pinY

  self.pins = newPins

  for _, p in ipairs(self.pins) do
    pin = p
    if pin:IsShown() then
      point, relativeTo, relativePoint, pinX, pinY = pin:GetPoint()
      pin.originalX = pinX / 10.02
      pin.originalY = -pinY / 6.68 -- TODO: use constants
      pin.originalW = pin:GetWidth()
      pin.originalH = pin:GetHeight()
      pin:SetParent(self.frame)
      pin:ClearAllPoints()
    end
  end
  self.initialised = true
end

function GoggleMaps.compat.pfQuest:handleUpdate()
  local Map = GoggleMaps.Map
  local mapId = Map.mapId
  local scale = Map.scale
  local clipW = Map.size.width
  local clipH = Map.size.height

  ---@type Frame
  local pin
  local x, y, w, h
  local worldX, worldY
  local clampedWidth, clampedHeight
  local adjustedX, adjustedY
  for _, p in ipairs(self.pins) do
    pin = p
    if pin:IsShown() then
      worldX, worldY = Utils.GetWorldPos(mapId, pin.originalX, pin.originalY)

      w = pin.originalW * scale
      h = pin.originalH * scale

      clampedWidth = math.min(pin.originalW, w)
      clampedHeight = math.min(pin.originalH, h)

      x = (worldX - Map.position.x - (pin.originalW / 2)) * scale + clipW / 2
      y = (worldY - Map.position.y - (pin.originalH / 2)) * scale + clipH / 2

      adjustedX = x + (w - clampedWidth) / 2
      adjustedY = y + (h - clampedHeight) / 2

      pin:SetPoint("TopLeft", adjustedX, -adjustedY)
      pin:SetWidth(clampedWidth)
      pin:SetHeight(clampedHeight)
    end
  end
  self.frame:SetFrameLevel(GoggleMaps.frameLevels.pfQuest)
end
