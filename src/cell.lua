local stateMachine = require "state"
local sounds       = require "sounds"

local cell         = {}
cell.__index       = cell

function cell:new(x, y)
  local c = {
    x = x,
    y = y,
    id = math.random(10000),

    render = false,   -- Used to determine if the cell should be drawn and blocks ray casting
    blocking = false, -- Used to determine if the cell blocks movement
    thin = false,     -- Used to determine if the cell is a thin wall, also used for doors
    door = false,     -- Used only as a rendering hint so sides can be drawn correctly
    textures = {},    -- Array used to store the textures for the cell
    animateSpeed = 0, -- Used to determine the speed of the animation for the cell
    item = nil,       -- Used to store the item in the cell, if any

    state = nil,      -- State machine for the cell, if any, currently only used for doors
  }

  setmetatable(c, self)
  self.__index = self

  return c
end

function cell:__tostring()
  return string.format("Cell(%d, %d)", self.x, self.y)
end

function cell:newDoor(x, y, map, open)
  local c = cell:new(x, y)

  c.thin = true
  c.render = true
  c.door = true
  c.blocking = true
  c.textures[1] = map.tileSet.images["door"]
  c.textures[2] = map.tileSet.images["door_opena"]
  c.textures[3] = map.tileSet.images["door_openb"]
  c.textures[4] = map.tileSet.images["door_openc"]
  c.textures[5] = map.tileSet.images["door_opend"]

  c.state = stateMachine:new()

  c.state:addState("closed", {
    onEnter = function(_, data, noSound)
      c.blocking = true;
      data.currentTexture = c.textures[1]
      if not noSound then sounds.doorClosed:play() end
    end
  })

  c.state:addState("open", {
    onEnter = function(_, data)
      c.blocking = false
      data.currentTexture = c.textures[5]
      sounds.doorOpen:play()
    end
  })

  c.state:addState("opening", {
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

  c.state:addState("closing", {
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

  c.state:changeState("closed", true)
  if open then
    c.state:changeState("open", true)
  end

  map.stateMachines[#map.stateMachines + 1] = c.state

  setmetatable(c, self)
  self.__index = self

  return c
end

return cell
