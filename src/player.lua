local Vec2 = require "vector"

local player = {}

function player:new(x, y)
  local p = {
    pos = Vec2:new(x, y),
    facing = Vec2:new(0, -1),
    camPlane = Vec2:new(1, 0),
    angle = 0,
    speed = 0,

    -- Constants
    fov = 70,
    fovRad = math.rad(70),
    maxSpeed = 3,
    acceleration = 4,
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

  local rad = math.rad(self.angle)
  self.facing.x = math.cos(rad)
  self.facing.y = math.sin(rad)

  -- Update camera plane based on the new facing direction
  self.camPlane.x = -self.facing.y
  self.camPlane.y = self.facing.x
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
  local ray = Vec2:new(0, 0)
  ray.x = self.facing.x + (self.camPlane.x * (screenX / love.graphics.getWidth() - 0.5) * self.fovRad)
  ray.y = self.facing.y + (self.camPlane.y * (screenX / love.graphics.getWidth() - 0.5) * self.fovRad)
  return ray:normalizeNew()
end

return player
