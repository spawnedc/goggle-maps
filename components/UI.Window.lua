setfenv(1, GoggleMaps)

GoggleMaps.UI.Window = {}

local INSET = 4

-- simple backdrop you can customize
---@type Backdrop
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

  local closeButton = CreateFrame("Button", name and (name .. "CloseButton") or nil, frame, "UIPanelCloseButton")
  closeButton:SetPoint("TopRight", frame, "TopRight", -1, -1)
  closeButton:SetFrameStrata("HIGH")
  closeButton:SetFrameLevel(frame:GetFrameLevel() + 2)
  closeButton:EnableMouse(true)
  closeButton:SetWidth(24)
  closeButton:SetHeight(24)

  -- client area inset (inside the border + below title)
  local baseInset = INSET

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
  function frame:SetContentSize()
    local w = self:GetWidth()
    local h = self:GetHeight()
    local cw = w - (insetLeft + insetRight)
    local ch = h - (insetTop + insetBottom)
    self.Content:SetWidth(cw)
    self.Content:SetHeight(ch)

    return cw, ch
  end

  -- api: set title text
  function frame:SetTitle(text) self.TitleText:SetText(text or "") end

  ---api: create a child frame inside the clipped content (no clipping by itself)
  ---@param childName string | nil
  ---@param w number?
  ---@param h number?
  ---@return Frame
  function frame:CreateChildFrame(childName, w, h)
    local child = CreateFrame("Frame", childName, self.Content)
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

  resizer:SetScript("OnMouseDown", function()
    resizer.isDragging = true
    frame:StartSizing(point)
  end)

  resizer:SetScript("OnUpdate", function()
    if resizer.isDragging then
      frame:SetContentSize()
    end
  end)

  resizer:SetScript("OnMouseUp", function()
    resizer.isDragging = false
    frame:StopMovingOrSizing()
  end)

  frame:SetContentSize()
end

-----------------------------------------------------------------------
-- Library public API
-----------------------------------------------------------------------

---Create a clipping window (acts like overflow:hidden for its children)
--- @param name string
--- @param width number
--- @param height number
--- @param parent? Frame
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
    content:SetWidth(w - 10)
    content:SetHeight(h - 22)
  end

  return win
end
