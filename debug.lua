setfenv(1, GoggleMaps)

local UI = GoggleMaps.UI.Window

local LINE_HEIGHT = 16

---@class DebugItem
---@field key string
---@field button Button
---@field value string | number | boolean
---@field valueFormatter function?

GMapsDebug = {
  ---@type table<DebugItem>
  items = {},
  contentFrame = nil
}

---Creates a button the list items
---@param key string
---@param value string | number | boolean
---@param anchorItem Button|Frame|nil
---@param valueFormatter function?
---@return Button
local function createButton(key, value, anchorItem, valueFormatter)
  local btn = CreateFrame("Button", key, GMapsDebug.contentFrame)
  btn:SetWidth(160)
  btn:SetHeight(LINE_HEIGHT)
  if not anchorItem then
    btn:SetPoint("TopLeft", GMapsDebug.contentFrame, "TopLeft", 0, 0)
  else
    btn:SetPoint("TopLeft", anchorItem, "BottomLeft", 0, 0)
  end

  btn.label = btn:CreateFontString(nil, "ARTWORK", "GameFontWhite")
  btn.label:SetPoint("Left", btn, "Left", 2, 0)
  btn.label:SetText(key)

  btn.text = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  btn.text:SetPoint("Left", btn, "Right", -20, 0)
  local label = tostring(value)

  if valueFormatter then
    label = valueFormatter(value)
  end

  btn.text:SetText(label)

  return btn
end

local function buildlist()
  local items = GMapsDebug.items
  local numItems = 0
  for i, thing in pairs(items) do
    ---@type DebugItem
    local item = thing
    if item.button then
      item.button:Hide()
      item.button = nil
    end

    local anchorItem = GMapsDebug.contentFrame

    if i > 1 then
      ---@type DebugItem
      local lastItem = items[i - 1]
      anchorItem = lastItem.button
    end

    item.button = createButton(item.key, item.value, anchorItem)

    numItems = numItems + 1
  end

  -- Adjust content height so scroll works
  GMapsDebug.contentFrame:SetHeight(numItems * LINE_HEIGHT)
end

function GMapsDebug:CreateDebugWindow()
  local title = GetAddOnMetadata(GoggleMaps.name, "Title")
  local debugFrame = UI:CreateWindow("GMapsDebug", 300, 500, UIParent)
  debugFrame:SetPoint("Right", 0, 0)
  debugFrame:SetTitle(title .. " Debug")

  local debugContent = debugFrame.Content
  debugContent:SetAllPoints()

  -- Create the scroll frame
  local scrollFrame = CreateFrame("ScrollFrame", "MyListScrollFrame", debugContent, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TopLeft", debugContent, "TopLeft", 2, 0)
  scrollFrame:SetPoint("BottomRight", debugContent, "BottomRight", -22, 0)

  -- Create the content frame that will hold the items
  self.contentFrame = CreateFrame("Frame", "MyListContent", scrollFrame)
  self.contentFrame:SetWidth(debugContent:GetWidth() - 20) -- same as visible width inside scroll

  scrollFrame:SetScrollChild(self.contentFrame)

  debugFrame:triggerResize()

  return debugFrame
end

---Adds an item to the watch list
---@param name string
---@param value string | number | boolean?
---@param valueFormatter function?
function GMapsDebug:AddItem(name, value, valueFormatter)
  local numItems = table.getn(GMapsDebug.items)
  local anchorItem = numItems > 0 and self.items[numItems].button or nil
  ---@type DebugItem
  local newItem = {
    key = name,
    value = value or '',
    button = createButton(name, value, anchorItem)
  }
  if valueFormatter then
    newItem.valueFormatter = valueFormatter
  end
  table.insert(self.items, newItem)

  self.contentFrame:SetHeight((numItems + 1) * LINE_HEIGHT)
end

function GMapsDebug:RemoveItem(name)
  local indexToRemove
  local items = self.items
  for i = 1, table.getn(items) do
    if items[i].key == name then
      indexToRemove = i
    end
  end
  if indexToRemove then
    local item = self.items[indexToRemove]
    item.button:Hide()
    item.button = nil
    self.items[indexToRemove] = nil
  end
  buildlist()
end

function GMapsDebug:UpdateItem(name, value)
  local items = self.items
  for i = 1, table.getn(items) do
    if items[i].key == name then
      ---@type DebugItem
      local item = items[i]
      local label = tostring(value)

      if item.valueFormatter then
        label = item.valueFormatter(value)
      end

      item.button.text:SetText(label)
    end
  end
end
