setfenv(1, GoggleMaps)

GoggleMaps.Minimap = {
  ---@type table<Frame>
  frames = {},
  minimapBlocksToDraw = 10
}

local function getMinimapTexture(block, x, y)
  local offset = (x * 100 + y) + block.offset

  return block[1][offset]
end

---Initialises the minimap frames
---@param parentFrame Frame
function GoggleMaps.Minimap:Init(parentFrame)
  Utils.print("Minimap init")
  -- Initialiseation has to be done here so other addons can override these
  local KalimdorBlocks = GoggleMaps.Map.MinimapBlocks.Kalimdor
  local AzerothBlocks = GoggleMaps.Map.MinimapBlocks.Azeroth

  -- TODO: Auto-generate this
  -- TODO: Random numbers, where do they come from?
  self.Blocks = {
    [1] = { KalimdorBlocks, offset = 1908, x = -1387.5660, y = -2060.4561 },
    [2] = { AzerothBlocks, offset = 2420, x = 2930.591080, y = -1480.211752 }
  }

  for n = 1, self.minimapBlocksToDraw ^ 2 do
    local tf = CreateFrame("Frame", nil, parentFrame)
    self.frames[n] = tf
    local t = tf:CreateTexture()
    tf.texture = t
    t:SetAllPoints(tf)
  end
end

function GoggleMaps.Minimap:GetMinimapInfo(mapId)
  local continentId = Utils.getContinentId(mapId)
  local block = self.Blocks[continentId]

  return block, block.x, block.y
end

function GoggleMaps.Minimap:HideMiniFrames()
  for n = 1, self.minimapBlocksToDraw ^ 2 do
    self.frames[n]:Hide()
  end
end

function GoggleMaps.Minimap:handleUpdate()
  local mapId = GoggleMaps.Map.mapId

  if not mapId then
    return
  end

  local miniT, basex, basey = self:GetMinimapInfo(mapId)
  if not miniT then
    self:HideMiniFrames()
    return
  end

  if GoggleMaps.Map.scale < 1.2 then
    self:HideMiniFrames()
    return
  end

  local Map = GoggleMaps.Map
  local f
  local frmNum = 1

  local baseScale = 0.416767770014 -- TODO: What?
  local frameWidth = 256 * baseScale
  local frameHeight = 256 * baseScale

  local miniX = math.floor((Map.position.x - basex) / frameWidth - self.minimapBlocksToDraw / 2 + .5)
  local miniY = math.floor((Map.position.y - basey) / frameHeight - self.minimapBlocksToDraw / 2 + .5)
  basex = basex + miniX * frameWidth
  basey = basey + miniY * frameHeight

  local row, col = 0, 0
  local frameX, frameY
  local scale = Map.scale
  local clipW = Map.size.width
  local clipH = Map.size.height
  local x = (basex - Map.position.x) * scale + clipW / 2
  local y = (basey - Map.position.y) * scale + clipH / 2
  local baseWidth = frameWidth * scale
  local baseHeight = frameHeight * scale


  for my = miniY, miniY + self.minimapBlocksToDraw - 1 do
    row = 0
    for mx = miniX, miniX + self.minimapBlocksToDraw - 1 do
      f = self.frames[frmNum]
      local txname = getMinimapTexture(miniT, mx, my)

      if txname then
        frameX = row * baseWidth + x
        frameY = col * baseHeight + y

        if Utils.ClipFrame(f, frameX, frameY, baseWidth, baseHeight, clipW, clipH) then
          f.texture:SetVertexColor(1, 1, 1, 1)
          txname = "Textures\\Minimap\\" .. txname
          f.texture:SetTexture(txname)
          f:SetFrameLevel(GoggleMaps.frameLevels.minimap)
        end
      else
        f:Hide()
      end

      row = row + 1
      frmNum = frmNum + 1
    end

    col = col + 1
  end
end
