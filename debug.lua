setfenv(1, GoggleMaps)

local UI = GoggleMaps.UI.Window

local LINE_HEIGHT = 16

GMapsDebug = {
  items = {},
  contentFrame = nil
}

local function createButton(key, value, anchorItem)
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
  btn.text:SetPoint("Left", btn, "Left", 82, 0)
  btn.text:SetText(value)

  return btn
end

local function buildlist()
  local items = GMapsDebug.items
  for i = 1, table.getn(items) do
    local item = items[i]

    if item.button then
      item.button:Hide()
      item.button = nil
    end

    local anchorItem = i > 1 and items[i - 1].button or GMapsDebug.contentFrame
    item.button = createButton(item.key, item.value, anchorItem)
  end

  -- Adjust content height so scroll works
  GMapsDebug.contentFrame:SetHeight(table.getn(items) * LINE_HEIGHT)
end

function GMapsDebug:CreateDebugWindow()
  local debugFrame = UI:CreateWindow("GMapsDebug", 300, 500, UIParent)
  debugFrame:SetPoint("TopLeft", 0, 0)
  debugFrame:SetTitle("Debug")

  local debugContent = debugFrame.Content

  -- Create the scroll frame
  local scrollFrame = CreateFrame("ScrollFrame", "MyListScrollFrame", debugContent, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TopLeft", debugContent, "TopLeft", 2, 0)
  scrollFrame:SetPoint("BottomRight", debugContent, "BottomRight", -22, 0)

  -- Create the content frame that will hold the items
  GMapsDebug.contentFrame = CreateFrame("Frame", "MyListContent", scrollFrame)
  GMapsDebug.contentFrame:SetWidth(160) -- same as visible width inside scroll
  scrollFrame:SetScrollChild(GMapsDebug.contentFrame)

  return debugFrame
end

function GMapsDebug:AddItem(name, value)
  local numItems = table.getn(GMapsDebug.items)
  local anchorItem = numItems > 0 and GMapsDebug.items[numItems].button or GMapsDebug.contentFrame
  table.insert(GMapsDebug.items, {
    key = name,
    value = value or '',
    button = createButton(name, value, anchorItem)
  })

  GMapsDebug.contentFrame:SetHeight((numItems + 1) * LINE_HEIGHT)
end

function GMapsDebug:RemoveItem(name)
  local indexToRemove
  local items = GMapsDebug.items
  for i = 1, table.getn(items) do
    if items[i].key == name then
      indexToRemove = i
    end
  end
  if indexToRemove then
    local item = GMapsDebug.items[indexToRemove]
    item.button:Hide()
    item.button = nil
    GMapsDebug.items[indexToRemove] = nil
  end
  buildlist()
end

function GMapsDebug:UpdateItem(name, value)
  local items = GMapsDebug.items
  for i = 1, table.getn(items) do
    if items[i].key == name then
      items[i].button.text:SetText(value)
    end
  end
end
