local vec2 = require "vector"
local sprite = {}

function sprite:new(x, y, name, cache)
  local obj = {
    pos = vec2:new(x, y),
    name = "bob",
    image = cache.images[name],
  }

  setmetatable(obj, self)
  self.__index = self

  return obj
end

-- Draw the sprite on the screen projected on the 2D plane
function sprite:draw(camPos, camDir, camPlane)
  local fov = math.rad(70)
  local spriteX = self.pos.x - camPos.x
  local spriteY = self.pos.y - camPos.y

  local scalePlane = camPlane * math.tan(fov / 2)


  local invDet = 1 / (scalePlane.x * camDir.y - camDir.x * scalePlane.y)

  local transformX = invDet * (camDir.y * spriteX - camDir.x * spriteY)
  local transformY = invDet * (-scalePlane.y * spriteX + scalePlane.x * spriteY)

  if transformY <= 0 then return end

  local screenX = (love.graphics.getWidth() / 2) * (1 + transformX / transformY)

  local spriteHeight = math.abs(love.graphics.getHeight() / transformY)
  local spriteWidth = spriteHeight

  local drawStartY = -spriteHeight / 2 + love.graphics.getHeight() / 2
  local drawStartX = -spriteWidth / 2 + screenX

  love.graphics.draw(self.image, drawStartX, drawStartY, 0, spriteWidth / self.image:getWidth(),
    spriteHeight / self.image:getHeight())
end

return sprite
