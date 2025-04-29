local json       = require "lib.rxi.json"
local imageCache = require "image-cache"
local item       = require "item"

local cell       = require "cell"

local map        = {}

function map:load(mapName)
  print("💾 Loading map: " .. mapName)

  -- Load the map data from JSON file in data/maps/level1.json
  local filePath = "data/maps/" .. mapName .. ".json"
  local fileData, _ = love.filesystem.read(filePath)
  assert(fileData, "Error loading map file: " .. filePath)

  local mapData = json.decode(fileData)
  assert(mapData, "Error decoding map JSON: " .. filePath)

  print("🗺️ Map '" ..
    mapData.name .. "' decoded ok, width: " .. mapData.width .. ", height: " .. mapData.height)

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
  m.name = "Untitled Level"
  m.tileSetName = mapData.tileset or "default"
  m.width = mapData.width
  m.height = mapData.height
  m.playerStartCell = {}
  m.playerStartDir = mapData.playerStartDir or 3
  m.tileSet = imageCache:load("assets/tilesets/" .. m.tileSetName)
  m.stateMachines = {}

  -- Loop over mapData.layout populate the cells
  for row = 1, #mapData.layout do
    local dataRow = mapData.layout[row]
    if #dataRow ~= m.width then
      error("Map row " .. row .. " has incorrect width: " .. #dataRow .. ", expected: " .. m.width)
    end

    for col = 1, #dataRow do
      local c = m.cells[col][row]

      -- It's a string so use sub to get the character
      local symbol = dataRow:sub(col, col)

      -- Set the cell's position
      c.x = col
      c.y = row

      -- Set the cell's render and blocking properties based on the map symbol
      c.render = false
      c.blocking = false

      if symbol == "@" then
        m.playerStartCell.x = col
        m.playerStartCell.y = row
      end

      if symbol == "#" then
        c.render = true
        c.blocking = true
        math.randomseed(c.id)
        local name = "wall_" .. math.random(1, 10)
        if m.tileSet.images[name] == nil then
          name = "wall"
        end

        c.textures[1] = m.tileSet.images[name]

        if m.tileSet.images[name .. "a"] ~= nil then
          c.textures[2] = m.tileSet.images[name .. "a"]
          c.animateSpeed = 0.7
        end

        if m.tileSet.images[name .. "b"] ~= nil then
          c.textures[3] = m.tileSet.images[name]
          c.textures[4] = m.tileSet.images[name .. "b"]
          c.animateSpeed = 0.7
        end
      end

      if symbol == "b" then
        c.item = item:new(c, "tank", 1)
        m.sprites[#m.sprites + 1] = c.item.sprite
        c.blocking = true
      end

      if symbol == "t" then
        c.item = item:new(c, "terminal", 0.7)
        m.sprites[#m.sprites + 1] = c.item.sprite
      end

      if symbol == "c" then
        c.item = item:new(c, "crate", 0.8)
        m.sprites[#m.sprites + 1] = c.item.sprite
      end

      if symbol == "h" then
        c.item = item:new(c, "hook", 1)
        m.sprites[#m.sprites + 1] = c.item.sprite
      end

      if symbol == "w" then
        c.item = item:new(c, "wires", 1)
        m.sprites[#m.sprites + 1] = c.item.sprite
      end

      if symbol == "|" or symbol == "-" then
        m.cells[col][row] = cell:newDoor(col, row, m, false)
      end
    end
  end

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
