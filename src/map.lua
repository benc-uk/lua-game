local json       = require "lib.rxi.json"
local imageCache = require "image-cache"
local item       = require "item"

local map        = {}
local cell       = {}
cell.__index     = cell

function cell:new(x, y)
  local c = {
    x = x,
    y = y,
    render = false,
    blocking = false,
    thin = false,
    door = false,
    openAmount = 0,
    item = nil,
    id = math.random(1000)
  }

  setmetatable(c, self)
  self.__index = self

  return c
end

function cell:__tostring()
  return string.format("Cell(%d, %d)", self.x, self.y)
end

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
      m.cells[i][j] = cell:new(i, j)
    end
  end

  -- Sprites held in their own array for easy of rendering/sorting
  m.sprites = {}

  -- Loop over mapData.layout populate the cells
  for rowIndex = 1, #mapData.layout do
    local dataRow = mapData.layout[rowIndex]
    for colIndex = 1, #dataRow do
      local c = m.cells[colIndex][rowIndex]
      local mapSymbol = dataRow[colIndex]

      if mapSymbol == "#" then
        c.render = true
        c.blocking = true
      end

      if mapSymbol == "b" then
        c.item = item:new(c, "barrel")
        m.sprites[#m.sprites + 1] = c.item.sprite
      end

      if mapSymbol == "c" then
        c.item = item:new(c, "chest")
        m.sprites[#m.sprites + 1] = c.item.sprite
      end

      if mapSymbol == "." then
        c.blocking = true
      end

      if mapSymbol == "|" or mapSymbol == "-" then
        c.thin = true
        c.render = true
        c.door = true
        c.openAmount = 0.6
        c.blocking = true
      end
    end
  end

  m.name = "Demo Dungeon"
  m.tileSetName = mapData.tileset or "default"
  m.width = mapData.width
  m.height = mapData.height
  m.playerStartCell = { mapData.playerStartCell[1], mapData.playerStartCell[2] }
  m.playerStartDir = mapData.playerStartDir or 0

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
