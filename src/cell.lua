local stateMachine = require "state"
local sounds       = require "sounds"

local cell         = {}
cell.__index       = cell

function cell:new(x, y)
  local c = {
    x            = x,
    y            = y,
    id           = math.random(10000),

    render       = false, -- Used to determine if the cell should be drawn and blocks ray casting
    thin         = false, -- Used to determine if the cell is a thin wall, also used for doors
    door         = false, -- Used only as a rendering hint so sides can be drawn correctly
    textures     = {},    -- Array used to store the textures for the cell
    animateSpeed = 0,     -- Used to determine the speed of the animation for the cell
    item         = nil,   -- Used to store the item in the cell, if any
    ceilingDecor = nil,   -- Used to store the ceiling decoration for the cell, if any

    state        = nil,   -- State machine for the cell, if any, currently only used for doors
    body         = nil,   -- Physics body for the cell, if any
  }

  setmetatable(c, self)
  self.__index = self

  return c
end

function cell:__tostring()
  return string.format("Cell(%d, %d)", self.x, self.y)
end

-- Adds a physics body & fixture to the cell for walls and doors
function cell:makeSolid(world)
  local shape = love.physics.newRectangleShape(1, 1)
  local body = love.physics.newBody(world, self.x + 0.5, self.y + 0.5, "static")
  local _ = love.physics.newFixture(body, shape, 1)
  self.body = body
end

-- Adds a small physics body & fixture to the cell, used for items
function cell:addItemObstruction(world)
  local shape = love.physics.newCircleShape(0.2)
  local body = love.physics.newBody(world, self.x + 0.5, self.y + 0.5, "static")
  local _ = love.physics.newFixture(body, shape, 1)
  self.body = body
end

-- Sets the cell to allow bodys to pass through it
function cell:unblock()
  if self.body then
    self.body:setActive(false)
  end
end

-- Sets the cell to block bodys from passing through it
function cell:block()
  if self.body then
    self.body:setActive(true)
  end
end

function cell:addDoor(open, world, tileSet, stateMachines)
  self.thin = true
  self.render = true
  self.door = true
  self.textures[1] = tileSet.images["door"]
  self.textures[2] = tileSet.images["door_opena"]
  self.textures[3] = tileSet.images["door_openb"]
  self.textures[4] = tileSet.images["door_openc"]
  self.textures[5] = tileSet.images["door_opend"]

  self.state = stateMachine:new()
  self:makeSolid(world)

  self.state:addState("closed", {
    onEnter = function(_, data, noSound)
      self:block()
      data.currentTexture = self.textures[1]
      if not noSound then sounds.doorClosed:play() end
    end
  })

  self.state:addState("open", {
    onEnter = function(_, data)
      self:unblock()
      data.currentTexture = self.textures[5]
      sounds.doorOpen:play()
    end
  })

  self.state:addState("opening", {
    onEnter = function(_, data)
      self:block()
      data.textureIndex = 1
      data.currentTexture = self.textures[data.textureIndex]
      data.timeToNextFrame = 0.2
      sounds.door:play()
    end,
    onUpdate = function(fsm, data, dt)
      data.timeToNextFrame = data.timeToNextFrame - dt
      if data.timeToNextFrame < 0 then
        data.textureIndex = data.textureIndex + 1
        if data.textureIndex > #self.textures then
          data.textureIndex = 5
          fsm:changeState("open")
        end

        data.currentTexture = self.textures[data.textureIndex]
        data.timeToNextFrame = 0.2
      end
    end
  })

  self.state:addState("closing", {
    onEnter = function(_, data)
      self:block()
      data.textureIndex = 5
      data.currentTexture = self.textures[data.textureIndex]
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

        data.currentTexture = self.textures[data.textureIndex]
        data.timeToNextFrame = 0.2
      end
    end
  })

  self.state:changeState("closed", true)
  if open then
    self.state:changeState("open", true)
  end

  stateMachines[#stateMachines + 1] = self.state
end

return cell
