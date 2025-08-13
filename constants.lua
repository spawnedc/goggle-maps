setfenv(1, SpwMap)

SPWMAP_FRAME_WIDTH = 1024
SPWMAP_FRAME_HEIGHT = 768

SPWMAP_DETAIL_FRAME_WIDTH = 1002
SPWMAP_DETAIL_FRAME_HEIGHT = 668

SPWMAP_MAP_TEXTURE_SIZE = 256
SPWMAP_NUM_MAP_COLUMNS = 4
SPWMAP_NUM_MAP_ROWS = 3
SPWMAP_WORLD_MAP_BASE_TEXTURE_PATH = "Interface\\WorldMap\\"

-- These represent continents and their blocks (4x3 in a 1-dimentional array)
-- Only blocks with 1s will be rendered, 0s will be ignored
SPWMAP_CONTINENT_BLOCKS = {
  [1] = { 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0 },
  [2] = { 0, 1, 1, 0, 0, 1, 1, 0, 0, 1, 1, 0 },
}
