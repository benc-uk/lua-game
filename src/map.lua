local json = require "lib.rxi.json"
local tileset = require "tileset"

local function newCell(x, y)
  return {
    x = x,
    y = y,
    isWall = false,
    isDoor = false,
    isExit = false,
  }
end

local function load(mapName)
  print("Loading map: " .. mapName)

  local map = {}
  for i = 1, 10 do
    map[i] = {}
    for j = 1, 10 do
      map[i][j] = newCell(i, j)
    end
  end

  -- Load the map data from JSON file in data/maps/level1.json
  local filePath = "data/maps/" .. mapName .. ".json"
  local data, _ = love.filesystem.read(filePath)
  assert(data, "Error loading map file: " .. filePath)

  local mapData = json.decode(data)
  assert(mapData, "Error decoding map JSON: " .. filePath)

  print("Map loaded and decoded successfully")

  -- loop over mapData.layout and fill the map with cells
  for rowIndex = 1, #mapData.layout do
    local dataRow = mapData.layout[rowIndex]
    for colIndex = 1, #dataRow do
      local cell = map[colIndex][rowIndex]
      local dataValue = dataRow[colIndex]
      if dataValue == 1 then
        cell.isWall = true
      end
    end
  end

  map.name = "Demo Dungeon"
  map.tileSetName = "dungeon"
  map.width = mapData.width or 10
  map.height = mapData.height or 10

  map.tileSet = tileset.load(map.tileSetName)

  return map
end

return {
  load = load,
}
