setfenv(1, SP)

local ui = VanillaUI

local FRAME_WIDTH = 500
local FRAME_HEIGHT = 500

local MAP_WIDTH = 1002
local MAP_HEIGHT = 668

local TEXTURE_SIZE = 256

SP = {
  isDragging = false,
  --- @type table<Frame>
  continentTextures = {}
}

function SP:Init()
  Utils.log('BOK')
  self.frame = ui:CreateWindow("MyAddonMain", FRAME_WIDTH, FRAME_HEIGHT, UIParent)
  self.frame:SetPoint("Center", 0, 0)
  self.frame:SetTitle("MyAddon")

  self.mapFrame = ui:CreateNestedWindow(self.frame, "MapFrame", MAP_WIDTH, MAP_HEIGHT, true)
  self.mapFrame:SetPoint("TopLeft", self.frame.Content, "TopLeft", 20, -40)
  self.mapFrame:SetBackdrop({ bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background' })
  self.mapFrame:SetBackdropColor(1, 0, 0, 1)

  SP:InitContinents()
end

function SP:onEvent()
  if event == "ADDON_LOADED" and arg1 == "spwmap-playground" then
    Utils.log("SP LOADED")
    self.frame:Show()
  end
end

function SP:InitContinents()
  local row, col = 0, 0

  for blockIndex = 1, 12 do
    local texturePath = "Interface\\WorldMap\\Kalimdor\\Kalimdor" .. blockIndex
    row = Utils.mod(blockIndex - 1, 4)
    col = -math.floor((blockIndex - 1) / 4)

    local continentFrame = CreateFrame("Frame", nil, self.mapFrame.Content)
    continentFrame:SetPoint("TopLeft", self.mapFrame.Content, "TopLeft", row * TEXTURE_SIZE, col * TEXTURE_SIZE)
    continentFrame:SetWidth(TEXTURE_SIZE)
    continentFrame:SetHeight(TEXTURE_SIZE)

    local t = continentFrame:CreateTexture(nil, "ARTWORK")
    t:SetAllPoints(continentFrame)
    t:SetTexture(texturePath)
  end
end

SP:Init()
