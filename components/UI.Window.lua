setfenv(1, GoggleMaps)

GoggleMaps.UI.Window = {}

local INSET = 4

-- simple backdrop you can customize
local BACKDROP = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 16,
  edgeSize = 16,
  insets = { left = INSET, right = INSET, top = INSET, bottom = INSET },
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
  frame:SetBackdropColor(0, 0, 0, 0.9)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)

  -- title bar (drag handle)
  local title = CreateFrame("Frame", name and (name .. "TitleBar") or nil, frame)
  title:SetPoint("TopLeft", frame, "TopLeft", INSET, -INSET)
  title:SetPoint("TopRight", frame, "TopRight", -INSET, -INSET)
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
  local baseInset = INSET + 1

  local insetLeft, insetRight, insetTop, insetBottom = baseInset, baseInset, title:GetHeight() + baseInset, baseInset

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
    self.Content:SetWidth(cw);
    self.Content:SetHeight(ch)
  end

  -- api: set title text
  function frame:SetTitle(text) self.TitleText:SetText(text or "") end

  -- api: create a child frame inside the clipped content (no clipping by itself)
  function frame:CreateChildFrame(childName, w, h, frameType)
    frameType = frameType or "Frame"
    local child = CreateFrame(frameType, childName, self.Content)
    if w and h then
      child:SetWidth(w)
      child:SetHeight(h)
    end
    return child
  end

  return frame
end

---Creates a resizer
---@param frame Frame
---@param point FramePoint
local function createResizer(frame, point)
  local resizer = CreateFrame("Button", nil, frame)
  resizer:SetPoint(point, frame, point, 0, 0)
  resizer:SetWidth(16)
  resizer:SetHeight(16)

  local function resizeContent()
    local content = frame.Content
    -- Update content size after resize
    local w, h = frame:GetWidth(), frame:GetHeight()
    content:SetWidth(w - 16)
    content:SetHeight(h - 36)
  end


  resizer:SetScript("OnMouseDown", function()
    resizer.isDragging = true
    frame:StartSizing(point)
  end)

  resizer:SetScript("OnUpdate", function()
    if resizer.isDragging then
      resizeContent()
    end
  end)

  resizer:SetScript("OnMouseUp", function()
    resizer.isDragging = false
    frame:StopMovingOrSizing()
  end)

  resizeContent()
end

-----------------------------------------------------------------------
-- Library public API
-----------------------------------------------------------------------

-- Create a clipping window (acts like overflow:hidden for its children)
function GoggleMaps.UI.Window:CreateWindow(name, width, height, parent)
  local win = CreateBaseWindow(name, width, height, parent)
  win:SetResizable(true)
  -- Resize handle
  createResizer(win, "BottomRight")
  createResizer(win, "BottomLeft")
  createResizer(win, "TopLeft")
  createResizer(win, "TopRight")

  function win:triggerResize()
    local content = win.Content
    -- Update content size after resize
    local w, h = win:GetWidth(), win:GetHeight()
    content:SetWidth(w - 16)
    content:SetHeight(h - 36)
  end

  return win
end

---Create a nested window inside a parent window's clipped content.
---The nested window ALSO clips its own children (overflow hidden inside overflow hidden).
---@param parentWindow Frame
---@param name string
---@param width number
---@param height number
---@return Frame
function GoggleMaps.UI.Window:CreateNestedWindow(parentWindow, name, width, height)
  -- Outer holder frame (visual container)
  local holder = CreateFrame("Frame", name, parentWindow.Content)
  holder:SetWidth(width)
  holder:SetHeight(height)

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

  -- Public references
  holder.Clip = clip
  holder.Content = content

  return holder
end
