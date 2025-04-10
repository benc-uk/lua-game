local json = require "lib.rxi.json"
local imageCache = require "image-cache"

local function newCell(x, y)
  return {
    x = x,
    y = y,
    isWall = false,
    item = nil,
  }
end

local map = {}

function map:load(mapName)
  print("Loading map: " .. mapName)

  -- Load the map data from JSON file in data/maps/level1.json
  local filePath = "data/maps/" .. mapName .. ".json"
  local data, _ = love.filesystem.read(filePath)
  assert(data, "Error loading map file: " .. filePath)

  local mapData = json.decode(data)
  assert(mapData, "Error decoding map JSON: " .. filePath)

  print("Map loaded and decoded successfully, width: " .. mapData.width .. ", height: " .. mapData.height)

  local m = {}
  m.cells = {}
  for i = 1, mapData.height do
    m.cells[i] = {}
    for j = 1, mapData.width do
      m.cells[i][j] = newCell(i, j)
    end
  end

  -- loop over mapData.layout and fill the map with cells
  for rowIndex = 1, #mapData.layout do
    local dataRow = mapData.layout[rowIndex]
    for colIndex = 1, #dataRow do
      local cell = m.cells[colIndex][rowIndex]
      local dataValue = dataRow[colIndex]
      if dataValue == "#" then
        cell.isWall = true
      end
    end
  end

  m.name = "Demo Dungeon"
  m.tileSetName = mapData.tileset
  m.width = mapData.width
  m.height = mapData.height

  m.tileSet = imageCache:load("assets/tilesets/" .. m.tileSetName)

  setmetatable(m, self)
  self.__index = self

  return m
end

function map:get(x, y)
  if x < 1 or x > self.width or y < 1 or y > self.height then
    return nil
  end
  return self.cells[math.floor(x)][math.floor(y)]
end

return map
