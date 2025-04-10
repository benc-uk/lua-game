local Vec2 = require "vector"

local player = {}


function player:new(x, y)
  local p = {
    pos = Vec2:new(x, y),
    facing = Vec2:new(1, 0),
    camPlane = Vec2:new(0, 0.66), -- Camera plane perpendicular to the facing direction
    angle = 0,
    speed = 0,

    -- Constants
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

  local oldDirX = self.facing.x
  local oldPlaneX = self.camPlane.x
  local cosA = math.cos(math.rad(a))
  local sinA = math.sin(math.rad(a))

  self.facing.x = self.facing.x * cosA - self.facing.y * sinA
  self.facing.y = oldDirX * sinA + self.facing.y * cosA

  self.camPlane.x = self.camPlane.x * cosA - self.camPlane.y * sinA
  self.camPlane.y = oldPlaneX * sinA + self.camPlane.y * cosA

  print("Facing: " .. self.facing.x .. ", " .. self.facing.y)
  print("CamPlane: " .. self.camPlane.x .. ", " .. self.camPlane.y)
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
  local cameraX = 2 * screenX / love.graphics.getWidth() - 1 -- x-coordinate in camera space
  ray.x = self.facing.x + self.camPlane.x * cameraX
  ray.y = self.facing.y + self.camPlane.y * cameraX
  return ray:normalizeNew()
end

return player
