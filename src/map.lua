local json           = require "lib.rxi.json"
local imageCache     = require "image-cache"
local item           = require "item"
local cell           = require "cell"

local sprites        = {}
local name           = "default"
local tileSetName    = "default"
local width          = 0
local height         = 0
local playerStart    = { x = 0, y = 0 }
local playerStartDir = 0
local tileSet        = nil
local stateMachines  = {}
local cells          = {}

local function load(mapName, world)
  print("💾 Loading map: " .. mapName)

  -- Load the map data from JSON file in data/maps/level1.json
  local filePath = "data/maps/" .. mapName .. ".json"
  local fileData, _ = love.filesystem.read(filePath)
  assert(fileData, "Error loading map file: " .. filePath)

  local mapData = json.decode(fileData)
  assert(mapData, "Error decoding map JSON: " .. filePath)

  width = mapData.width
  height = mapData.height
  name = mapData.name or "default"
  tileSetName = mapData.tileset or "default"
  tileSet = imageCache:load("assets/tilesets/" .. "tech")

  playerStartDir = mapData.playerStartDir or 0

  print("🗺️ Map '" .. name .. "' decoded ok, width: " .. width .. ", height: " .. height)


  for i = 1, mapData.height do
    cells[i] = {}
    for j = 1, mapData.width do
      cells[i][j] = cell:new(i, j)
    end
  end

  local playerSet = false

  if #mapData.layout ~= height then
    error("Map height " .. #mapData.layout .. " does not match map data height: " .. height)
  end

  -- Loop over mapData.layout populate the cells
  for row = 1, #mapData.layout do
    local dataRow = mapData.layout[row]
    if #dataRow ~= width then
      error("Map row " .. row .. " has incorrect width: " .. #dataRow .. ", expected: " .. width)
    end

    for col = 1, #dataRow do
      local c = cells[col][row]

      -- It's a string so use sub to get the character
      local symbol = dataRow:sub(col, col)

      if symbol == "@" then
        playerStart.x = col
        playerStart.y = row
        playerSet = true
      end

      if symbol == "#" then
        c.render = true
        math.randomseed(c.id)
        local wallName = "wall_" .. math.random(1, 10)
        if tileSet.images[wallName] == nil then
          wallName = "wall"
        end

        c.textures[1] = tileSet.images[wallName]

        if tileSet.images[wallName .. "a"] ~= nil then
          c.textures[2] = tileSet.images[wallName .. "a"]
          c.animateSpeed = 0.7
        end

        if tileSet.images[wallName .. "b"] ~= nil then
          c.textures[3] = tileSet.images[wallName]
          c.textures[4] = tileSet.images[wallName .. "b"]
          c.animateSpeed = 0.7
        end
        c:makeSolid(world)
      end

      if symbol == "b" then
        c.item = item:new(c, "tank", 1)
        sprites[#sprites + 1] = c.item.sprite
        c:addItemObstruction(world)
      end

      if symbol == "t" then
        c.item = item:new(c, "terminal", 0.9)
        sprites[#sprites + 1] = c.item.sprite
        c:addItemObstruction(world)
      end

      if symbol == "c" then
        c.item = item:new(c, "crate", 0.85)
        sprites[#sprites + 1] = c.item.sprite
        c:addItemObstruction(world)
      end

      if symbol == "|" or symbol == "-" then
        c:addDoor(false, world, tileSet, stateMachines)
      end

      if symbol == ":" then
        c.thin = true
        c.render = true
        c:makeSolid(world)
        c.textures[1] = tileSet.images["grate"]
      end

      if symbol == "'" then
        c.thin = true
        c.render = true
        c:makeSolid(world)
        c.textures[1] = tileSet.images["window_3"]
      end

      if symbol == " " then
        -- % chance of wires from ceiling
        if math.random(1, 100) <= 8 then
          c.ceilingDecor = item:new(c, "wires", 1)
          sprites[#sprites + 1] = c.ceilingDecor.sprite
        end

        -- % chance of hook from ceiling
        if math.random(1, 100) <= 8 and c.ceilingDecor == nil then
          c.ceilingDecor = item:new(c, "hook", 1)
          sprites[#sprites + 1] = c.ceilingDecor.sprite
        end
      end
    end
  end

  -- Check if player start cell was set
  if not playerSet then
    error("Player start cell not set in map layout")
  end
end

local function getCell(x, y)
  if x < 1 or x > width or y < 1 or y > height then
    return nil
  end

  return cells[math.floor(x)][math.floor(y)]
end

return {
  load = load,
  getCell = getCell,
  playerStart = playerStart,
  stateMachines = stateMachines,
  sprites = sprites,
  getTileSet = function()
    return tileSet
  end,
  getTileSetName = function()
    return tileSetName
  end,
  getPlayerStartDir = function()
    return playerStartDir
  end,
}
