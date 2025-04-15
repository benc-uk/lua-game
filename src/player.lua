local vec2 = require "vector"
local magic = require "magic"

local player = {}

function player:new(x, y)
  local p = {
    -- Constants
    maxSpeed = 3,
    acceleration = 4,

    pos = vec2:new(x, y),
    facing = vec2:new(1, 0),
    camPlane = vec2:new(0, magic.FOV), -- Camera plane perpendicular to the facing direction
    angle = 0,
    speed = 0,
  }

  setmetatable(p, self)
  self.__index = self

  return p
end

function player:rotate(a)
  self.angle = self.angle + a
  if self.angle >= 360 then
    self.angle = self.angle - 360
  elseif self.angle < 0 then
    self.angle = self.angle + 360
  end

  self.facing.x = math.cos(math.rad(self.angle))
  self.facing.y = math.sin(math.rad(self.angle))
  self.camPlane.x = -self.facing.y * magic.FOV
  self.camPlane.y = self.facing.x * magic.FOV
end

function player:move(dt)
  self.pos = self.pos + self.facing * self.speed * dt
end

function player:accel()
  self.speed = self.speed + (self.acceleration * love.timer.getDelta())
  if self.speed >= self.maxSpeed then
    self.speed = self.maxSpeed
  end
end

function player:decel()
  self.speed = self.speed - (self.acceleration * love.timer.getDelta())
  if self.speed <= -self.maxSpeed then
    self.speed = -self.maxSpeed
  end
end

function player:comeToStop()
  if self.speed > 0 then
    self.speed = self.speed - (self.acceleration * 2 * love.timer.getDelta())
    if self.speed < 0 then
      self.speed = 0
    end
  elseif self.speed < 0 then
    self.speed = self.speed + (self.acceleration * 2 * love.timer.getDelta())
    if self.speed > 0 then
      self.speed = 0
    end
  end
end

function player:getRay(screenX)
  local cameraX = 2 * screenX / love.graphics.getWidth() - 1 -- X-coordinate in camera space

  local ray = vec2:new(
    self.facing.x + self.camPlane.x * cameraX,
    self.facing.y + self.camPlane.y * cameraX
  )

  return ray:normalizeNew()
end

return player
