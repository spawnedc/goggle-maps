setfenv(1, SpwMap)
SpwMap.Map = {
  Area = {},
  Overlay = {},
  MapInfo = {
    [1] = {
      Name = "Kalimdor",
      FileName = "Kalimdor",
      X = 0,
      Y = 500,
    },
    [2] = {
      Name = "Eastern Kingdoms",
      FileName = "Azeroth",
      X = 3784,
      Y = -200,
    },
  },
  initialised = false,
  isDragging = false,
  isZooming = false,
  scale = 0.5,
  maxScale = 10,
  minScale = 0.1,
  effectiveScale = 0.5,
  position = {
    x = 0,
    y = 0
  },
  size = {
    width = SPWMAP_DETAIL_FRAME_WIDTH,
    height = SPWMAP_DETAIL_FRAME_HEIGHT
  },
  scroll = {
    x = 0,
    y = 0
  },
}
