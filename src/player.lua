local vec2         = require "vector"
local consts       = require "consts"
local stateMachine = require "state"
local sounds       = require "sounds"

local player       = {}
player.__index     = player

function player:new(x, y, world)
  local shape = love.physics.newCircleShape(0.15)
  local body = love.physics.newBody(world, x, y, "dynamic")
  body:setMass(1)
  body:setLinearDamping(10)
  body:setInertia(0)
  body:setAngularDamping(25)

  local fix = love.physics.newFixture(body, shape, 1)
  fix:setFriction(0)
  fix:setCategory(1) -- Player category

  local p = {
    moveForce = 0.1585,
    turnSpeed = math.rad(0.19), -- radians per second
    mouseSensitivity = 0.002,   -- radians per pixel

    facing = vec2:new(1, 0),
    camPlane = vec2:new(0, consts.FOV), -- Camera plane perpendicular to the facing direction
    angle = 0,

    state = stateMachine:new(),
    body = body,
  }

  p.state:addState("idle", {})
  p.state:changeState("idle")

  setmetatable(p, self)
  self.__index = self

  return p
end

function player:update(dt)
  -- Update the state machine
  self.state:update(dt)

  self:setAngle(self.body:getAngle())
end

function player:setAngle(a)
  self.angle = a
  if self.angle < 0 then
    self.angle = self.angle + math.pi * 2
  end
  if self.angle > math.pi * 2 then
    self.angle = self.angle - math.pi * 2
  end
  self.body:setAngle(self.angle)

  self.facing.x = math.cos(self.angle)
  self.facing.y = math.sin(self.angle)
  self.camPlane.x = -self.facing.y * consts.FOV
  self.camPlane.y = self.facing.x * consts.FOV
end

function player:move(dt, dir)
  self.body:applyForce(
    self.facing.x * dir * dt * self.moveForce,
    self.facing.y * dir * dt * self.moveForce
  )
  sounds.playFoot()
end

function player:turn(dt, dir)
  self.body:applyTorque(dir * dt * self.turnSpeed)
end

function player:strafe(dt, dir)
  self.body:applyForce(
    self.facing.y * dir * dt * self.moveForce,
    -self.facing.x * dir * dt * self.moveForce
  )
end

-- Gets the player's position in world coordinates
function player:getPosition()
  local x, y = self.body:getPosition()
  return vec2:new(x, y)
end

-- Constructs a ray from the player's position to the screen coordinates
function player:getRay(screenX)
  local cameraX = 2 * screenX / love.graphics.getWidth() - 1 -- X-coordinate in camera space

  local ray = vec2:new(
    self.facing.x + self.camPlane.x * cameraX,
    self.facing.y + self.camPlane.y * cameraX
  )

  return ray:normalizeNew()
end

-- Fires a ray from the player's position and returns any cell within a distance of 1
function player:getCellFacing(map)
  local x, y = self.body:getPosition()
  local ray = vec2:new(self.facing.x, self.facing.y)
  local cellX = math.floor(x + ray.x * 0.8)
  local cellY = math.floor(y + ray.y * 0.8)

  return map:get(cellX, cellY)
end

return player
