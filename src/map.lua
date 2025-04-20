local json         = require "lib.rxi.json"
local imageCache   = require "image-cache"
local item         = require "item"
local stateMachine = require "state"
local sounds       = require "sounds"

local map          = {}
local cell         = {}
cell.__index       = cell

function cell:new(x, y)
  local c = {
    x = x,
    y = y,
    render = false,
    blocking = false,
    thin = false,
    door = false,
    textures = {},
    animateSpeed = 0,
    item = nil,
    id = math.random(10000),
    fsm = nil,
  }

  setmetatable(c, self)
  self.__index = self

  return c
end

function cell:__tostring()
  return string.format("Cell(%d, %d)", self.x, self.y)
end

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
  m.name = "Demo Dungeon"
  m.tileSetName = mapData.tileset or "default"
  m.width = mapData.width
  m.height = mapData.height
  m.playerStartCell = {}
  m.playerStartDir = mapData.playerStartDir or 0
  m.tileSet = imageCache:load("assets/tilesets/" .. m.tileSetName)
  m.fsmList = {}

  -- Loop over mapData.layout populate the cells
  for rowIndex = 1, #mapData.layout do
    local dataRow = mapData.layout[rowIndex]
    for colIndex = 1, #dataRow do
      local c = m.cells[colIndex][rowIndex]
      local mapSymbol = dataRow[colIndex]

      if mapSymbol == "@" then
        m.playerStartCell.x = colIndex
        m.playerStartCell.y = rowIndex
      end

      if mapSymbol == "#" then
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

      if mapSymbol == "b" then
        c.item = item:new(c, "tank", 1)
        m.sprites[#m.sprites + 1] = c.item.sprite
        c.blocking = true
      end

      if mapSymbol == "t" then
        c.item = item:new(c, "terminal", 0.7)
        m.sprites[#m.sprites + 1] = c.item.sprite
      end

      if mapSymbol == "c" then
        c.item = item:new(c, "crate", 0.8)
        m.sprites[#m.sprites + 1] = c.item.sprite
      end

      if mapSymbol == "h" then
        c.item = item:new(c, "hook", 1)
        m.sprites[#m.sprites + 1] = c.item.sprite
      end

      if mapSymbol == "w" then
        c.item = item:new(c, "wires", 1)
        m.sprites[#m.sprites + 1] = c.item.sprite
      end

      if mapSymbol == "|" or mapSymbol == "-" then
        c.thin = true
        c.render = true
        c.door = true
        c.blocking = false
        c.textures[1] = m.tileSet.images["door"]
        c.textures[2] = m.tileSet.images["door_opena"]
        c.textures[3] = m.tileSet.images["door_openb"]
        c.textures[4] = m.tileSet.images["door_openc"]
        c.textures[5] = m.tileSet.images["door_opend"]

        c.fsm = stateMachine:new()

        c.fsm:addState("closed", {
          onEnter = function(_, data, noSound)
            c.blocking = true;
            data.currentTexture = c.textures[1]
            if not noSound then sounds.doorClosed:play() end
          end
        })

        c.fsm:addState("open", {
          onEnter = function(_, data)
            c.blocking = false
            data.currentTexture = c.textures[5]
            sounds.doorOpen:play()
          end
        })

        c.fsm:addState("opening", {
          onEnter = function(_, data)
            c.blocking = true
            data.textureIndex = 1
            data.currentTexture = c.textures[data.textureIndex]
            data.timeToNextFrame = 0.2
            sounds.door:play()
          end,
          onUpdate = function(fsm, data, dt)
            data.timeToNextFrame = data.timeToNextFrame - dt
            if data.timeToNextFrame < 0 then
              data.textureIndex = data.textureIndex + 1
              if data.textureIndex > #c.textures then
                data.textureIndex = 5
                fsm:changeState("open")
              end

              data.currentTexture = c.textures[data.textureIndex]
              data.timeToNextFrame = 0.2
            end
          end
        })

        c.fsm:addState("closing", {
          onEnter = function(_, data)
            c.blocking = true
            data.textureIndex = 5
            data.currentTexture = c.textures[data.textureIndex]
            data.timeToNextFrame = 0.2
            sounds.door:play()
          end,
          onUpdate = function(fsm, data, dt)
            data.timeToNextFrame = data.timeToNextFrame - dt
            if data.timeToNextFrame < 0 then
              data.textureIndex = data.textureIndex - 1
              if data.textureIndex < 1 then
                fsm:changeState("closed")
              end

              data.currentTexture = c.textures[data.textureIndex]
              data.timeToNextFrame = 0.2
            end
          end
        })

        c.fsm:changeState("closed", true)
        m.fsmList[#m.fsmList + 1] = c.fsm
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
