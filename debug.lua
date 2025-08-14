setfenv(1, SpwMap)

local UI = SpwMap.UI.Window

local LINE_HEIGHT = 16

SpwDebug = {
  items = {},
  contentFrame = nil
}

local function createButton(key, value, anchorItem)
  local btn = CreateFrame("Button", key, SpwDebug.contentFrame)
  btn:SetWidth(160)
  btn:SetHeight(LINE_HEIGHT)
  if not anchorItem then
    btn:SetPoint("TopLeft", SpwDebug.contentFrame, "TopLeft", 0, 0)
  else
    btn:SetPoint("TopLeft", anchorItem, "BottomLeft", 0, 0)
  end

  btn.label = btn:CreateFontString(nil, "ARTWORK", "GameFontWhite")
  btn.label:SetPoint("Left", btn, "Left", 2, 0)
  btn.label:SetText(key)

  btn.text = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  btn.text:SetPoint("Left", btn, "Left", 82, 0)
  btn.text:SetText(value)

  return btn
end

local function buildlist()
  local items = SpwDebug.items
  for i = 1, table.getn(items) do
    local item = items[i]

    if item.button then
      item.button:Hide()
      item.button = nil
    end

    local anchorItem = i > 1 and items[i - 1].button or SpwDebug.contentFrame
    item.button = createButton(item.key, item.value, anchorItem)
  end

  -- Adjust content height so scroll works
  SpwDebug.contentFrame:SetHeight(table.getn(items) * LINE_HEIGHT)
end

function SpwDebug:CreateDebugWindow()
  local debugFrame = UI:CreateWindow("SpwMapDebug", 300, 500, UIParent)
  debugFrame:SetPoint("TopLeft", 0, 0)
  debugFrame:SetTitle("Debug")

  local debugContent = debugFrame.Content

  -- Create the scroll frame
  local scrollFrame = CreateFrame("ScrollFrame", "MyListScrollFrame", debugContent, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TopLeft", debugContent, "TopLeft", 2, 0)
  scrollFrame:SetPoint("BottomRight", debugContent, "BottomRight", -22, 0)

  -- Create the content frame that will hold the items
  SpwDebug.contentFrame = CreateFrame("Frame", "MyListContent", scrollFrame)
  SpwDebug.contentFrame:SetWidth(160) -- same as visible width inside scroll
  scrollFrame:SetScrollChild(SpwDebug.contentFrame)

  return debugFrame
end

function SpwDebug:AddItem(name, value)
  local numItems = table.getn(SpwDebug.items)
  Utils.log(numItems)
  local anchorItem = numItems > 0 and SpwDebug.items[numItems].button or SpwDebug.contentFrame
  table.insert(SpwDebug.items, {
    key = name,
    value = value or '',
    button = createButton(name, value, anchorItem)
  })

  SpwDebug.contentFrame:SetHeight((numItems + 1) * LINE_HEIGHT)
end

function SpwDebug:RemoveItem(name)
  local indexToRemove
  local items = SpwDebug.items
  for i = 1, table.getn(items) do
    if items[i].key == name then
      indexToRemove = i
    end
  end
  if indexToRemove then
    local item = SpwDebug.items[indexToRemove]
    item.button:Hide()
    item.button = nil
    SpwDebug.items[indexToRemove] = nil
  end
  buildlist()
end

function SpwDebug:UpdateItem(name, value)
  local items = SpwDebug.items
  for i = 1, table.getn(items) do
    if items[i].key == name then
      items[i].button.text:SetText(value)
    end
  end
end
