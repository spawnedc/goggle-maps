setfenv(1, GoggleMaps)

GoggleMaps.Player = {
  ---@type Frame
  frame = nil,
  isMoving = false,
  ---@type number
  direction = 0,
  position = {
    x = 0,
    y = 0
  },
  size = {
    width = 30,
    height = 30
  }
}

---Initialiases the Player component
---@param parentFrame Frame
function GoggleMaps.Player:Init(parentFrame)
  Utils.print("PlayerInit")
  local frameName = parentFrame:GetName() .. "PlayerFrame"
  local playerFrame = CreateFrame("Frame", frameName, parentFrame)
  playerFrame:SetWidth(self.size.width)
  playerFrame:SetHeight(self.size.height)
  playerFrame:SetFrameStrata("TOOLTIP")

  local playerTexture = playerFrame:CreateTexture(frameName .. "Texture", "OVERLAY")
  playerTexture:SetAllPoints()
  playerTexture:SetTexture("Interface\\Minimap\\MinimapArrow")

  playerFrame.texture = playerTexture

  self.frame = playerFrame

  GMapsDebug:AddItem("Player X", self.position.x, Utils.numberFormatter(2))
  GMapsDebug:AddItem("Player Y", self.position.y, Utils.numberFormatter(2))
  GMapsDebug:AddItem("Is moving", self.isMoving)
  GMapsDebug:AddItem("Direction", self.direction)
  GMapsDebug:AddItem("PframeX")
  GMapsDebug:AddItem("PframeY")
end

---Updates the player component
---@param isRealMap boolean
function GoggleMaps.Player:handleUpdate(isRealMap)
  local playerZoneX, playerZoneY
  if isRealMap then
    playerZoneX, playerZoneY = GetPlayerMapPosition("player")
  else
    playerZoneX = 0
    playerZoneY = 0
  end

  if playerZoneX > 0 or playerZoneY > 0 then -- Update world position of player if we can get it
    playerZoneX = playerZoneX * 100
    playerZoneY = playerZoneY * 100
    self.isMoving = playerZoneX ~= self.position.x or playerZoneY ~= self.position.y
    self.position.x = playerZoneX
    self.position.y = playerZoneY
  else
    self.isMoving = false
    playerZoneX = self.position.x
    playerZoneY = self.position.y
  end


  local x, y = Utils.GetWorldPos(GoggleMaps.Map.realMapId, playerZoneX, playerZoneY)
  local direction = ({ _G['Minimap']:GetChildren() })[9]:GetFacing() * -1

  local scale = GoggleMaps.Map.scale
  local clipW = GoggleMaps.Map.size.width
  local clipH = GoggleMaps.Map.size.height
  x = ((x - GoggleMaps.Map.position.x) * scale + clipW / 2) - self.size.width / 2
  y = ((y - GoggleMaps.Map.position.y) * scale + clipH / 2) - self.size.height / 2

  if not self.isMoving and direction ~= self.direction then
    self.isMoving = true
    self.direction = direction
  end

  GMapsDebug:UpdateItem("Player X", playerZoneX)
  GMapsDebug:UpdateItem("Player Y", playerZoneY)
  GMapsDebug:UpdateItem("Is moving", self.isMoving)
  GMapsDebug:UpdateItem("Direction", self.direction)

  GMapsDebug:UpdateItem("PframeX", x)
  GMapsDebug:UpdateItem("PframeY", y)

  Utils.ClipFrame(self.frame, x, y, 30, 30, clipW, clipH)

  local co = math.cos(direction)
  local si = math.sin(direction)
  local texX1 = -.5
  local texX2 = .5
  local texY1 = -.5
  local texY2 = .5
  local t1x, t1y, t2x, t2y, t3x, t3y, t4x, t4y
  t1x = texX1 * co + texY1 * si + .5
  t1y = texX1 * -si + texY1 * co + .5
  t2x = texX1 * co + texY2 * si + .5
  t2y = texX1 * -si + texY2 * co + .5
  t3x = texX2 * co + texY1 * si + .5
  t3y = texX2 * -si + texY1 * co + .5
  t4x = texX2 * co + texY2 * si + .5
  t4y = texX2 * -si + texY2 * co + .5
  self.frame.texture:SetTexCoord(t1x, t1y, t2x, t2y, t3x, t3y, t4x, t4y)

  local level = GoggleMaps.Map.frameLevel
  self.frame:SetFrameLevel(level + 100)
end
