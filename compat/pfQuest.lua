setfenv(1, GoggleMaps)

GoggleMaps.compat.pfQuest = {
  ---@type Frame
  frame = nil,
  initialised = false,
  ---@type table<Frame>
  pins = {}

}

function GoggleMaps.compat.pfQuest:Init(parentFrame)
  Utils.debug("Compat:pfQuest")
  self.frame = CreateFrame("Frame", "GoggleMapsCompatpfQuestFrame", parentFrame)
  self.frame:SetAllPoints()
  self.frame:SetFrameLevel(GoggleMaps.frameLevels.pfQuest)

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
      Utils.print("%s", pin.title)
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
  for _, p in ipairs(self.pins) do
    pin = p
    if pin:IsShown() then
      worldX, worldY = Utils.GetWorldPos(mapId, pin.originalX, pin.originalY)

      x              = (worldX - Map.position.x) * scale + clipW / 2
      y              = (worldY - Map.position.y) * scale + clipH / 2
      w              = math.min(pin.originalW, pin.originalW * scale)
      h              = math.min(pin.originalH, pin.originalH * scale)

      pin:SetPoint("TopLeft", x, -y)
      pin:SetWidth(w)
      pin:SetHeight(h)
    end
  end
end
