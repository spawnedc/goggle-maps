setfenv(1, SP)

VanillaUI = {
  name = 'VanillaUI'
}

-- simple backdrop you can customize
local BACKDROP = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 16,
  edgeSize = 16,
  insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

--- Create a movable window frame with a titlebar and clipper
--- @param name string
--- @param width number
--- @param height number
--- @param parent? Frame
local function CreateBaseWindow(name, width, height, parent)
  parent = parent or UIParent

  -- outer frame (visual container + title bar)
  local frame = CreateFrame("Frame", name, parent)
  frame:SetWidth(width);
  frame:SetHeight(height)
  frame:SetBackdrop(BACKDROP)
  frame:SetBackdropColor(0, 0, 0, 0.75)
  -- frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function() frame:StartMoving() end)
  frame:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
  frame:SetClampedToScreen(true)

  -- title bar (drag handle)
  local title = CreateFrame("Frame", name and (name .. "TitleBar") or nil, frame)
  title:SetPoint("TopLeft", frame, "TopLeft", 6, -6)
  title:SetPoint("TopRight", frame, "TopRight", -6, -6)
  title:SetHeight(18)
  title:EnableMouse(true)
  title:SetScript("OnMouseDown", function() frame:StartMoving() end)
  title:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)

  local titleTex = title:CreateTexture(nil, "BACKGROUND")
  titleTex:SetAllPoints(title)
  titleTex:SetTexture(0.1, 0.1, 0.1, 0.9)

  local titleText = title:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  titleText:SetPoint("Left", title, "Left", 4, 0)
  titleText:SetText(name or "Window")

  -- client area inset (inside the border + below title)
  local insetLeft, insetRight, insetTop, insetBottom = 8, 8, 28, 8

  -- SCROLLFRAME as a clipper = "overflow: hidden"
  local clip = CreateFrame("ScrollFrame", name and (name .. "Clip") or nil, frame)
  clip:SetPoint("TopLeft", frame, "TopLeft", insetLeft, -insetTop)
  clip:SetPoint("BottomRight", frame, "BottomRight", -insetRight, insetBottom)

  -- content frame: everything you add goes here; anything outside clip is hidden
  local content = CreateFrame("Frame", name and (name .. "Content") or nil, clip)
  content:SetWidth(width - (insetLeft + insetRight))
  content:SetHeight(height - (insetTop + insetBottom))
  clip:SetScrollChild(content)

  -- lock scrolling to (0,0) so it behaves like overflow:hidden
  clip:SetScript("OnMouseWheel", function() end) -- no-op
  clip:SetHorizontalScroll(0)
  clip:SetVerticalScroll(0)

  -- public-ish fields
  frame.TitleBar  = title
  frame.TitleText = titleText
  frame.Clip      = clip
  frame.Content   = content

  -- api: resize window and keep clip/content in sync
  function frame:SetClientSize(w, h)
    -- overall size includes border/title; just resize the frame
    self:SetWidth(w); self:SetHeight(h)
    local cw = w - (insetLeft + insetRight)
    local ch = h - (insetTop + insetBottom)
    self.Content:SetWidth(cw); self.Content:SetHeight(ch)
  end

  -- api: set title text
  function frame:SetTitle(text) self.TitleText:SetText(text or "") end

  -- api: create a child frame inside the clipped content (no clipping by itself)
  function frame:CreateChildFrame(childName, w, h, frameType)
    frameType = frameType or "Frame"
    local child = CreateFrame(frameType, childName, self.Content)
    if w and h then
      child:SetWidth(w); child:SetHeight(h)
    end
    return child
  end

  return frame
end

-----------------------------------------------------------------------
-- Library public API
-----------------------------------------------------------------------

-- Create a clipping window (acts like overflow:hidden for its children)
function VanillaUI:CreateWindow(name, width, height, parent)
  local win = CreateBaseWindow(name, width, height, parent)
  return win
end

---Create a nested window inside a parent window's clipped content.
---The nested window ALSO clips its own children (overflow hidden inside overflow hidden).
---@param parentWindow Frame
---@param name string
---@param width number
---@param height number
---@param clampToParentBounds boolean
---@return Frame
function VanillaUI:CreateNestedWindow(parentWindow, name, width, height, clampToParentBounds)
  -- Outer holder frame (visual container)
  local holder = CreateFrame("Frame", name, parentWindow.Content)
  holder:SetWidth(width)
  holder:SetHeight(height)
  holder:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  holder:SetBackdropColor(0, 0, 0, 0.6)

  -- ScrollFrame for clipping
  local clip = CreateFrame("ScrollFrame", name .. "Clip", holder)
  clip:SetPoint("TopLeft", holder, "TopLeft", 0, 0)
  clip:SetPoint("BottomRight", holder, "BottomRight", 0, 0)

  -- Content frame inside the ScrollFrame
  local content = CreateFrame("Frame", name .. "Content", clip)
  content:SetWidth(width)
  content:SetHeight(height)
  clip:SetScrollChild(content)

  -- lock scroll so it behaves like overflow:hidden
  clip:SetHorizontalScroll(0)
  clip:SetVerticalScroll(0)

  -- Make draggable relative to parent content
  holder:SetMovable(false)
  holder:EnableMouse(true)
  holder:RegisterForDrag("LeftButton")

  holder:SetScript("OnDragStart", function()
    holder.isDragging = true
    local cursorX, cursorY = GetCursorPosition()
    holder.dragOffsetX = cursorX / UIParent:GetScale() - holder:GetLeft()
    holder.dragOffsetY = cursorY / UIParent:GetScale() - holder:GetTop()
  end)

  holder:SetScript("OnDragStop", function()
    holder.isDragging = false
  end)

  holder:SetScript("OnUpdate", function()
    if holder.isDragging then
      local cursorX, cursorY = GetCursorPosition()
      local parent = holder:GetParent()
      local scale = UIParent:GetScale()
      local newX = (cursorX / scale) - parent:GetLeft() - holder.dragOffsetX
      local newY = (cursorY / scale) - parent:GetTop() - holder.dragOffsetY

      if clampToParentBounds == true then
        -- Clamp to parent content bounds
        local maxX = parent:GetWidth() - holder:GetWidth()
        if newX > 0 then newX = 0 end
        if newX < maxX then newX = maxX end

        local maxY = parent:GetHeight() - holder:GetHeight()
        if newY < 0 then newY = 0 end
        if newY > -maxY then newY = -maxY end
      end

      holder:ClearAllPoints()
      holder:SetPoint("TopLeft", parent, "TopLeft", newX, newY)
    end
  end)

  -- Public references
  holder.Clip = clip
  holder.Content = content

  return holder
end
